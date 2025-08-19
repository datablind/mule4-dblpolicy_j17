# Anypoint Datablind Policy

ANypoint Data Blind policy protects sensitive data in API response by encrypting the sensitive fields. Sensitive fields are protected by encryption (AES/FPE) and masking. Users requiring sensitive date is required to provide a valid Override-Token provided by DataBlind. Users providing an expired or empty Override-Token will only get the encrypted data.


## API Responses
 
 ![Concept](/assets/DataBlind-Data-Sample.jpg)

# How to apply DataBlind to your API

## Publish Datablind Assets to your exchange 

1. Publish Datablind Connector to your exchange.
   Follow the instructions at https://github.com/mjegann5/anypoint-data-blind-connector
   
2. Publish Datablind Policy to your exchange
* A. Clone this repo
```
       git clone https://github.com/mjegann5/anypoint-datablind-policy.git
```
* B. In pom.xml replace ANYPOINT_ORG_ID by your Anypoint Org Id
```
       <groupId>ANYPOINT_ORG_ID</groupId> => <groupId>5tdfgceb5-fd1f-456d-aaa2-19cdsddcea</groupId>
```
* C. Run the maven command to deploy datablind policy to your exchange.
  anypoint_username and anypoint_password are your anypoint platform credentials.
  muleentrepo_username and muleentrepo_password are the anypoint enterprise repo credentials. Your anypoint platform admin will be able to provide this.
  Contact mjegann@kavisoft.net to get a valid cwrepo_password.)
```
	mvn deploy -DskipTests -s .\settings.xml -Dmuleentrepo_username="******" -Dmuleentrepo_password="******" -Danypoint_username="******" -Danypoint_password="******" -Dcwrepo_username="Token" -Dcwrepo_password="******************"
```
## Configure Policy in API Manager

1. Policy parameters
   
| Parameter | Description | Required | Example |
| --------- | ----------- | -------- | ------- |
| Datablind Key | Encryption Key used by the DataBlind | Required  | #["1234567812345678"] |
| Manually Specify Sensitive Fields | Select if you want to manually specify the sensitive fields in the API response | Required  | Click to Select |
| Sentitive Fields | Sensitive fields in the API response | Required  | #[{    "Title" : "FE:PersonName"  }] |
| Eligible HTTP Codes | Apply Datablind only when the API response has the following HTTP Codes | Required  | #["200,201,202,205,213"] |
| Override Token for DataBlind | When a valid override token is provided, Datablind returns the unencrypted and unmasked data | Optional  | #[attributes.headers['dataBlindToken']] |
| Passphrase used when creating the Override Token for DataBlind | When a valid override token passphrase is provided, Datablind returns the unencrypted and unmasked data  | Optional  | #[attributes.headers['dataBlindPassphrase']] |

   
2. Example Policy Configuration

   ![Concept](/assets/DataBlind-Policy.JPG)
