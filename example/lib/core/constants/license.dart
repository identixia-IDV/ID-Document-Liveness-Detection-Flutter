/// Demo FP1 licenses — same keys as native DocumentReader Android / iOS Apps.
library;

import 'dart:io' show Platform;

const androidApplicationId = 'com.identixia.documentliveness';
const iosBundleId = 'com.identixia.documentliveness.app';

const androidLicense =
    
    
    'pyyR2AECG3auhbQYVvWlYu0hmL0lQbXlGp7IdhSfEDTGwHwAAAARrbtGvWyvrYyL+UUOYFk4mWL/WDKn4caOVcuEHhICh6aBzL3MqmahIe0mnlVDC6kldHrRMoL+15CsS6AG98fApbhFjMO2Umg+u/chSpCnp8XLcQdi3tZqT5TXba5ltzhIxgJbIrUFeiOGxsMPM4FuBViMCLdYJhEKPAOzaAAwZgIxAJ8Gxg7RfBZt0CxKpxYuf4oJiNof0KmLOS0WSM6KS+EDz5WGpkFbE86qI2TNkBDq4AIxAOOi5kkEIvXNSJUUDWxErZF4R2XttVNBdOT2jA4kGqw2mDuWGYskYVfsFovL/7Y/MA==';

const iosLicense =
    
    
    'pyyR2AEC4o0LYfkA70x40FEJ6rmOf0UoFV87Qos9ktixCXwAAACN1p3nctW0y5BaFFuLzKCL+FWQ5mbRocw+i4UYtY1P/MFCXaAk8+G929vlUvoT9IEXjNjppY0Uh0t1KXF9kbcvjptBYlfIzDiDLKaE4T+mNYcM8DYA+EYcCDNapYo/PxiGBGbhCsIJig4gKm/hHT/01wCLbuQWSixieaEqZgAwZAIwRAFAWfzSNKivQ58SaPrZrMoMQvzC2rgXTvoFQYayM8+M6qt3Yxy7RrMFZ2rigzg4AjBVHEmPtK//ZsiqDMptePNzRi2JRKw0O+4lFhJcW7KkuEfd58sn7KfdvCjVIk4oXCw=';

String demoLicense() => Platform.isIOS ? iosLicense : androidLicense;
