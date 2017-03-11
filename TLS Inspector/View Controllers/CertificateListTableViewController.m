#import "CertificateListTableViewController.h"
#import "InspectorTableViewController.h"
#import "UIHelper.h"
#import "CHCertificate.h"
#import "CHCertificateChain.h"

@interface CertificateListTableViewController () {
    UIHelper * uihelper;
    CHCertificate * selectedCertificate;
}

@property (weak, nonatomic) IBOutlet UIView * headerView;
@property (weak, nonatomic) IBOutlet UILabel * headerViewLabel;
@property (weak, nonatomic) IBOutlet UIButton * headerButton;
@property (strong, nonatomic) CHCertificateChain * certificateChain;
@property (strong, nonatomic) CHCertificateChain * chainFactory;

- (IBAction)headerButton:(id)sender;

@end

@implementation CertificateListTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    uihelper = [UIHelper sharedInstance];
    self.chainFactory = [CHCertificateChain new];
    self.headerViewLabel.text = l(@"Loading...");
    if (![self.host hasPrefix:@"http"]) {
        self.host = [NSString stringWithFormat:@"https://%@", self.host];
    }

#ifdef EXTENSION
    [self.navigationItem
     setLeftBarButtonItem:[[UIBarButtonItem alloc]
                           initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                           target:self
                           action:@selector(dismissView:)]];
#endif
    [NSThread detachNewThreadSelector:@selector(loadCertificates) toTarget:self withObject:nil];
}

- (void) loadCertificates {
    [self.chainFactory
     certificateChainFromURL:[NSURL URLWithString:self.host]
     finished:^(NSError * _Nullable error, CHCertificateChain * _Nullable chain) {
         if (error) {
             [uihelper
              presentAlertInViewController:self
              title:l(@"Could not get certificates")
              body:error.localizedDescription
              dismissButtonTitle:l(@"Dismiss")
              dismissed:^(NSInteger buttonIndex) {
#ifdef MAIN_APP
                  [self.navigationController popViewControllerAnimated:YES];
#else
                  [self.extensionContext completeRequestReturningItems:self.extensionContext.inputItems completionHandler:nil];
#endif
              }];
         } else {
             self.certificateChain = chain;
             dispatch_async(dispatch_get_main_queue(), ^{
                 if (chain.trusted) {
                     self.headerViewLabel.text = l(@"Trusted Chain");
                     self.headerView.backgroundColor = [UIColor colorWithRed:0.298 green:0.686 blue:0.314 alpha:1];
                 } else {
                     self.headerViewLabel.text = l(@"Untrusted Chain");
                     self.headerView.backgroundColor = [UIColor colorWithRed:0.957 green:0.263 blue:0.212 alpha:1];
                 }
                 self.headerViewLabel.textColor = [UIColor whiteColor];
                 [self.tableView reloadData];
                 self.headerButton.hidden = NO;
                 if (self.index) {
                     NSUInteger certIndex = [self.index unsignedIntegerValue];
                     if ((chain.certificates.count - 1) >= certIndex) {
                         selectedCertificate = chain.certificates[certIndex];
                         [self performSegueWithIdentifier:@"ViewCert" sender:nil];
                     } else {
                         NSLog(@"Cert index is out of bounds %lu > %lu", (unsigned long)certIndex, chain.certificates.count - 1);
                     }
                 }
             });
         }
     }];
}

#ifdef EXTENSION
- (void) dismissView:(id)sender {
    [self.extensionContext completeRequestReturningItems:self.extensionContext.inputItems completionHandler:nil];
}
#endif

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.certificateChain.certificates.count > 0 ? l(@"Certificate Chain") : @"";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"ViewCert"]) {
        [(InspectorTableViewController *)[segue destinationViewController] loadCertificate:selectedCertificate forDomain:self.host];
    }
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.certificateChain.certificates.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CHCertificate * cert = [self.certificateChain.certificates objectAtIndex:indexPath.row];
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"Basic"];
    cell.textLabel.text = [cert summary];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    selectedCertificate = [self.certificateChain.certificates objectAtIndex:indexPath.row];
    [self performSegueWithIdentifier:@"ViewCert" sender:nil];
}

- (IBAction)headerButton:(id)sender {
    NSString * title = self.certificateChain.trusted ? l(@"Trusted Chain") : l(@"Untrusted Chain");
    NSString * body = self.certificateChain.trusted ? l(@"trusted_chain_description") : l(@"untrusted_chain_description");
    [uihelper
     presentAlertInViewController:self
     title:title
     body:body
     dismissButtonTitle:l(@"Dismiss")
     dismissed:nil];
}
@end
