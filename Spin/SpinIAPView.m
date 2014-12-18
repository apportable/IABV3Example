//
//  SpinIAPView.m
//  Spin
//
//  Copyright (c) 2013 Apportable. All rights reserved.
//

// For testing IAP

#import "SpinIAPView.h"

#ifdef APPORTABLE
//hacking open the way to call this method to generate a fake SKProduct
@interface SKProduct(ExposeMethod)
- (id)initWithLocalizedDescription:(NSString *)aDescription title:(NSString *)aTitle price:(NSDecimalNumber *)aPrice priceLocale:(NSLocale *)aPriceLocale productIdentifier:(NSString *)aProductIdentifier internalProductType:(NSString *)aProductType;
@end
#endif

@interface SpinIAPView() {
    NSMutableArray *_buttons;
    NSMutableDictionary *_buttonToProduct;
    SKProductsRequest *_productsRequest;
    SKProductsResponse *_productsList;
}

@end

@implementation SpinIAPView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self initView];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];
    if (self) {
        // Initialization code
        [self initView];
    }
    return self;
}

- (void)initView
{    
    _buttons = [NSMutableArray array];
    _buttonToProduct = [NSMutableDictionary dictionary];
    [self setBackgroundColor:[UIColor grayColor]];
    NSLog(@"-------------------------initWithView");
    
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];

    // The IABv3 billing service take a bit of time to be ready, so the dispatch_after() is necessary
    double delayInSeconds = 5.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self requestProductData];
#ifdef APPORTABLE
        // With IABv3, restoring purchases is cheap, so you should initiate a restoreCompletedTransactions during startup.
        // This will clear out any transactions that failed to "completely complete", (for example during cases where
        // the network dropped during the process of making a purchase).
        // NOTE: if you do not consume a prior purchase then it is an error to re-attempt to purchase the same item
        [self restorePurchases];
#endif
    });
}

- (void)requestProductData
{
    NSMutableSet *productIdentifiers = [NSMutableSet set];
    [productIdentifiers addObject:@"com.apportable.spin.nonconsumable1"];
    for (int i=1;i<=10;i++){
        [productIdentifiers addObject:[NSString stringWithFormat:@"com.apportable.spin.consumable%d",i]];
    }
    _productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:productIdentifiers];
    [_productsRequest setDelegate:self];
    
    NSLog(@"Requesting IAP product data... %@", _productsRequest);
    [_productsRequest start];
}

- (void)purchaseItem:(UIButton *)sender
{
    SKProduct *product = _buttonToProduct[[NSValue valueWithNonretainedObject:sender]];
    NSLog(@"purchasing product %@", product);
    SKPayment *payment = [SKPayment paymentWithProduct:product];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

-(void)restorePurchases
{
    NSLog(@"restoring purchases");
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

#pragma mark -
#pragma mark SKProductsRequestDelegate methods

#ifdef APPORTABLE
- (SKProduct*) allocGooglePlayStaticTestProduct:(NSString*) productId title:(NSString*) title
{
    return [[SKProduct alloc] initWithLocalizedDescription:title
                                                     title:title
                                                     price:[NSDecimalNumber one]
                                               priceLocale:[NSLocale currentLocale]
                                         productIdentifier:productId
                                       internalProductType:@"inapp"];
}
#endif

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    for (UIButton *button in _buttons){
        [button removeFromSuperview];
    }
    [_buttons removeAllObjects];
    [_buttonToProduct removeAllObjects];
    
    _productsList = response;
    
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    
    NSMutableArray *products = [NSMutableArray array];
    
    #ifdef APPORTABLE
    [products addObject:[self allocGooglePlayStaticTestProduct:@"android.test.purchased" title:@"Static Test: Purchased"]];
    [products addObject:[self allocGooglePlayStaticTestProduct:@"android.test.canceled" title:@"Static Test: Cancelled"]];
    [products addObject:[self allocGooglePlayStaticTestProduct:@"android.test.refunded" title:@"Static Test: Refunded"]];
    [products addObject:[self allocGooglePlayStaticTestProduct:@"android.test.item_unavailable" title:@"Static Test: Unavailable"]];
    #endif
    
    [products addObjectsFromArray:response.products];
    
    for (int i=0; i < [products count]; ++i) {
        SKProduct *product = [products objectAtIndex:i];
        if (product) {
            NSLog(@"Product id: %@" , product.productIdentifier);
            NSLog(@"Product title: %@" , product.localizedTitle);
            NSLog(@"Product description: %@" , product.localizedDescription);
            NSLog(@"Product price: %@" , product.price);
            NSLog(@"Product price locale: %@" , product.priceLocale);
            NSString *price;
#ifdef APPORTABLE
            price = [product performSelector:@selector(_priceString)];
#else
            [numberFormatter setLocale:product.priceLocale];
            price = [numberFormatter stringFromNumber:product.price];
#endif
            UIButton *button = [self addProductButtonWithName:product.productIdentifier price:price];
            [button setFrame:CGRectMake(10.0, 10.0 + (i*50.0), 300, 44)];
            [_buttons addObject:button];
            [_buttonToProduct setObject:product forKey:[NSValue valueWithNonretainedObject:button]];
        }
    }
    
    for (NSString *invalidProductId in response.invalidProductIdentifiers) {
        NSLog(@"INVALID PRODUCT ID: %@" , invalidProductId);
    }
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
    // NOTE: Google IAB can sometimes catch spurious errors, so attempt to gracefully handle them here
    // (For example querying for products "too early" during app startup may result in error, so schedule a refetch here)
    static int retryTimes = 0;
    if (++retryTimes > 5)
    {
        NSLog(@"Aborting retries for products.");
        return;
    }
    NSLog(@"Attempting refetch of products...");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self requestProductData];
    });
}

#pragma mark -

-(UIButton *)addProductButtonWithName:(NSString *)product price:(NSString *)price {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    NSString *str = product;
    [button setTitle:str forState:UIControlStateNormal];
    [button setTitle:str forState:UIControlStateHighlighted];
    [button setTitle:str forState:UIControlStateSelected];
    [button setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor greenColor] forState:UIControlStateHighlighted];
    [button setTitleColor:[UIColor greenColor] forState:UIControlStateSelected];
    [button setBackgroundColor:[UIColor redColor]];
    [self addSubview:button];
    [button addTarget:self action:@selector(purchaseItem:) forControlEvents:UIControlEventTouchUpInside];
    return button;
}

#pragma mark -
#pragma mark SKPaymentTransactionObserver methods

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    NSLog(@"----------------------------paymentQueue:updatedTransactions:");
    for (SKPaymentTransaction *txn in transactions) {
        BOOL finish = NO;
        switch (txn.transactionState) {
            case SKPaymentTransactionStatePurchasing:
                NSLog(@"SKPaymentTransactionStatePurchasing txn: %@", txn);
                break;
            case SKPaymentTransactionStatePurchased:
                NSLog(@"SKPaymentTransactionStatePurchased: %@", txn);
                finish = [self handleTransaction:txn];
                break;
            case SKPaymentTransactionStateFailed:
                NSLog(@"SKPaymentTransactionStateFailed: %@", txn);
                break;
            case SKPaymentTransactionStateRestored:
                NSLog(@"SKPaymentTransactionStateRestored: %@", txn);
                NSLog(@"Original transaction: %@", [txn originalTransaction]);
                NSLog(@"Original transaction payment: %@", [[txn originalTransaction] payment]);
                // To deal with IABv3 race conditions, network outages, app crashes, etc that may occur when purchasing/consuming products,
                // you should initiate a restoreCompletedTransactions on app startup and consume any restored consumables here.
                finish = [self handleTransaction:txn];
                break;
            default:
                NSLog(@"UNKNOWN SKPaymentTransactionState: %@", txn);
                break;
        }
        NSLog(@"SKPaymentTransaction id:%@",txn.transactionIdentifier);
        if( txn.payment != nil )
        {
            NSLog(@"SKPaymentTransaction productIdentifier:%@",txn.payment.productIdentifier);
        }
        if( txn.error != nil )
        {
            NSLog(@"SKPaymentTransaction error:%@",txn.error.localizedDescription);
            NSLog(@"SKPaymentTransaction error user-info:%@",txn.error.userInfo);
        }
        if (finish) {
            [[SKPaymentQueue defaultQueue] finishTransaction:txn];
        }
    }
}

- (BOOL)handleTransaction:(SKPaymentTransaction *)txn
{
    BOOL handled = YES;
    NSString *productId = [[txn payment] productIdentifier];
#ifdef APPORTABLE
    // You are going to have to know if the product is consumable or not -- consumable products are called "unmanaged"
    // products in your Google Developer Console.
    // In this example app, all consumable products have ".consumable" in the product identifier, so consume those now
    if ([productId rangeOfString:@".consumable"].location != NSNotFound) {
        NSLog(@"Consuming product %@ ...", productId);
        handled = [[SKPaymentQueue defaultQueue] consumePurchase:txn];
        if (!handled) {
            NSLog(@"OOPS, unable to consume product");
        }
    }
#endif
    
    if (handled) {
        // We can now credit the purchase and/or send it to our server for receipt verification
        // ...
        NSLog(@"Consumed product %@", productId);
    }
    
    return handled;
}

- (void)paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray *)transactions
{
    NSLog(@"----------------------------paymentQueue:removedTransactions:");
    for (SKPaymentTransaction *txn in transactions) {
        NSLog(@"removed transaction: %@", txn);
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
    NSLog(@"----------------------------paymentQueue:restoreCompletedTransactionsFailedWithError: %@", error);
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    NSLog(@"----------------------------paymentQueueRestoreCompletedTransactionsFinished:");
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedDownloads:(NSArray *)downloads
{
    NSLog(@"----------------------------paymentQueue:updatedDownloads:");
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
