IABV3Example
============

To enable the IABv3 flow do one of the following:
1. Add APGoogleIABV3Transitional to your info.plist and set it to true. 
2. Set GOOGLEIABV3=yes when compiling and it will append APGoogleIABV3Transitional to your info.plist when compiling. 
3. Add "GOOGLEIABV3":true in the options for configuration.json


Finally, to consume purchases, we have created an API:

@interface SKPaymentQueue(Apportable)
- (BOOL)consumePurchase:(SKPaymentTransaction *)transaction;
@end

We recommend calling that method before calling -[queue finishTransaction:] on the consumable. We also recommend waiting to call finishTransaction: until you receive YES from the consumePurchase: call.

There are some caveats with using the IABv3 purchase flow. For instance a user may purchase a consumable item, but before receiving the callback from google to award them the item, they might close or kill the app, and they won't receive the purchase! Then they'll try to purchase again, but they won't be able to, because...it's not consumable in IABv3. To bypass this scenario, we recommend restoring purchases on startup just to make sure.

To build for IABv3, you will still need to include SIGNING_PUBKEY and ANDROID_KEYSTORE in the env when building with Apportable.
