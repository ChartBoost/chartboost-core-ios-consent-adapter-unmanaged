# Chartboost Core Unmanaged Consent Adapter

The Chartboost Core Unmanaged Consent Adapter allows users to manage their own CMP integration directly, instead of relying
on Chartboost Core and a consent adapter to manage the CMP integration for them.

The use of the Unmanaged Consent Adapter is not preferred. Use one of the public Core consent adapters instead, for a 
streamlined integration without the need to to manage the CMP SDK yourself.

Important information regarding the Unmanaged Consent Adapter:

- Users are responsible for setting new consent info in the Unmanaged Consent Adapter when this info is updated by the CMP.
Failure to do so will result in frameworks that depend on Core for consent to have outdated consent info.

- Users must take care to format the consent info set in the Unmanaged Consent Adapter by using the constants defined in
`ConsentKeys` and `ConsentValues` when proper. For more info see the ChartboostCore SDK documentation.
Failure to do so will result in frameworks that depend on Core for consent to have outdated consent info.

- Chartboost Core SDK APIs to show consent dialogs are no-ops with this adapter.

## Minimum Requirements

| Plugin | Version |
| ------ | ------ |
| Chartboost Core SDK | 1.0.0+ |
| Cocoapods | 1.11.3+ |
| iOS | 13.0+ |
| Xcode | 15.0+ |

## Integration

In your `Podfile`, add the following entry:
```
pod 'ChartboostCoreConsentAdapterUnmanaged'
```

## Contributions

We are committed to a fully transparent development process and highly appreciate any contributions. Our team regularly monitors and investigates all submissions for the inclusion in our official adapter releases.

Refer to our [CONTRIBUTING](CONTRIBUTING.md) file for more information on how to contribute.

## License

Refer to our [LICENSE](LICENSE.md) file for more information.
