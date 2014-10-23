IABV3Example
============

*NOTE: Google will no longer support In-App Billing version 2 beginning in January 2015.*

With IABv3 it is the app's responsibility to _consume_ all purchases, (even for unmanaged products).  For this purpose
we have created this sample code.

To enable the IABv3 purchase flow add `GOOGLEIABV3=yes` when compiling.  (As of Apportable SDK v1.1.21, IABv3 is default
enabled).

We have augmented the SKPaymentQueue.h header with the following category to allow you to consume purchases:

```
@interface SKPaymentQueue(Apportable)
- (BOOL)consumePurchase:(SKPaymentTransaction *)transaction;
@end
```

- We recommend calling that method before calling `-[queue finishTransaction:]` on the consumable. We also recommend waiting to call `finishTransaction:` until you receive YES from the `consumePurchase:` call.

- There are some caveats with using the IABv3 purchase flow. For instance a user may purchase a consumable item, but before receiving the callback from google to award them the item, they might close or kill the app, and they won't receive the purchase! Then they'll try to purchase again, but they won't be able to, because...it has not been consumed yet!  To bypass this scenario, we recommend restoring purchases on startup just to make sure.

- To build for IABv3, you will still need to include SIGNING_PUBKEY and ANDROID_KEYSTORE in the env when building with Apportable.


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

