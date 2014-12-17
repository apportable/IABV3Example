IABV3Example
============

*NOTE: Google will no longer support In-App Billing version 2 beginning in January 2015.*  As of Apportable SDK v1.1.21,
IABv3 is default enabled.  With IABv3 it is your app's responsibility to _consume all unmanaged products_.

We have added an API for consuming unmanaged products to SKPaymentQueue:

```
@interface SKPaymentQueue(Apportable)
- (BOOL)consumePurchase:(SKPaymentTransaction *)transaction;
@end
```

- We recommend calling that method before calling `-[SKPaymentQueue finishTransaction:]` on the product. We also recommend waiting to call `finishTransaction:` until you receive YES from the `consumePurchase:` call.

- There are some caveats with using the IABv3 purchase flow. For instance a user may purchase a consumable item, but before receiving the callback from google to award them the item, they might close or kill the app, and they won't receive the purchase! Then they'll try to purchase again, but they won't be able to, because...it has not been consumed yet!  To bypass this scenario, we recommend restoring purchases on startup just to make sure.  The example source incorporates all these best practices and comments their usage.

- To build for IABv3, you will still need to include SIGNING_PUBKEY and ANDROID_KEYSTORE in the env when building with Apportable.

- Your app will need to differentiate between "non-consumable" (managed) and "consumable" (unmanaged) products.  You should only call `consumePurchase:` on the "consumable" (unmanaged) ones.


Google Developer Console
------------------------

You can import the following CSV file to create the In-App products that work with this app:

```
Product ID,Published State,Purchase Type,Auto Translate,Locale; Title; Description,Auto Fill Prices,Price
com.apportable.spin.consumable1,published,managed_by_publisher,false,en_US; Test Thing; It's a test Item.,false,US; 990000
com.apportable.spin.consumable2,published,managed_by_publisher,false,en_US; Test Item 2; It does stuff and things!,false,US; 990000
com.apportable.spin.consumable3,published,managed_by_publisher,false,en_US; Test Item 3; HELLO,false,US; 990000
com.apportable.spin.consumable4,published,managed_by_publisher,false,en_US; Test Item 4; HELLO,false,US; 990000
com.apportable.spin.consumable5,published,managed_by_publisher,false,en_US; Test Item 5; HELLO,false,US; 990000
com.apportable.spin.consumable6,published,managed_by_publisher,false,en_US; Test Item 6; HELLO,false,US; 990000
com.apportable.spin.consumable7,published,managed_by_publisher,false,en_US; Test Item 7; HELLO,false,US; 990000
com.apportable.spin.consumable8,published,managed_by_publisher,false,en_US; Test Item 8; HELLO,false,US; 990000
com.apportable.spin.consumable9,published,managed_by_publisher,false,en_US; Test Item 9; HELLO,false,US; 990000
com.apportable.spin.consumable10,published,managed_by_publisher,false,en_US; Test Item 10; HELLO,false,US; 990000
com.apportable.spin.nonconsumable1,published,managed_by_android,false,en_US; Test Nonconsumable; This does stuff.,false,US; 990000
```

NOTE: the app should be published to at least an alpha version before you can do live testing of purchases.

Stress-testing IABv3
--------------------

The IABv3 implementation in the Apportable platform and this sample app should be robust to network outages and app
crashing.  The following are tests you may wish to perform yourself to verify that everything is robust in your own app.

1. *Baseline* : verify that purchase flow works as intended for both managed and unmanged products without any abberant behavior.

1. *Pre-consumption crash test* : Purchase an unmanaged product, verify that Google reports a successful purchase, and
   immediately background/kill your app before it receives the purchase callback.  Verify that restarting app results in
   proper credit of unmanaged product.  Verify also that you can purchase the same product again.

1. Experiment with other failure-to-deliver cases and see that your app does eventually credit the product upon later
   launch when connectivity to Google Play Store is available.

