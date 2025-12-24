# Anypoint Datablind Policy

Anypoint Data Blind policy protects sensitive data in API response by encrypting the sensitive fields. Sensitive fields are protected by encryption (AES/FPE) and masking. Users requiring sensitive date is required to provide a valid Override-Token provided by DataBlind. Users providing an expired or empty Override-Token will only get the encrypted data.


## API Responses
 
 ![Concept](/assets/DataBlind-Data-Sample.jpg)

# How to apply DataBlind to your API

## Apply Datablind Policy to your API 

1. API Manager -> Select your API Instance -> Policies
   
2. Select DataBlind policy loacted under Custom Category

## Configure Policy in API Manager

1. Policy parameters
   
| Parameter | Description | Required | Example |
| --------- | ----------- | -------- | ------- |
| Datablind Key | Encryption Key used by the DataBlind | Required  | #["1234567812345678"] |
| Manually Specify Sensitive Fields | Select if you want to manually specify the sensitive fields in the API response | Required  | Click to Select |
| Sentitive Fields | Sensitive fields in the API response | Required  | #[{    "Title" : "FE:PersonName"  }] |
| DataBlind AI Redaction Service URI | URI for DataBlind redaction service securely hosted in AWS. Used when sensitive fields are not specified manually. This service uses AI to determine the sensitive fields and encrypts the values | Required  | #['https://kwoz0lfnn8.execute-api.us-west-1.amazonaws.com/Dev'] |
| API Key for DataBlind AI Redaction Service | API Key for DataBlind redaction service securely hosted in AWS. Used when sensitive fields are not specified manually. This service uses AI to determine the sensitive fields and encrypts the values. Contact datablindsupport@ztensor to get a new API Key. | Required  | #['w4i8ru24oifhfdskfjoweaihf'] |
| Eligible HTTP Codes | Apply Datablind only when the API response has the following HTTP Codes | Required  | #["200,201,202,205,213"] |
| Override Token for DataBlind | When a valid override token is provided, Datablind returns the unencrypted and unmasked data | Optional  | #[attributes.headers['dataBlindToken']] |
| Passphrase used when creating the Override Token for DataBlind | When a valid override token passphrase is provided, Datablind returns the unencrypted and unmasked data  | Optional  | #[attributes.headers['dataBlindPassphrase']] |

   
2. Example Policy Configuration

   ![Concept](/assets/DataBlind-Policy.JPG)
