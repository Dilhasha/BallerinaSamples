import ballerinax/salesforce as sfdc;
import ballerinax/trigger.salesforce as sfdcListener;
import ballerina/io;
import ballerina/http;

// Salesforce client configuration parameters
type OAuth2RefreshTokenGrantConfig record {
    string refreshUrl = "https://login.salesforce.com/services/oauth2/token";
    string refreshToken;
    string clientId;
    string clientSecret;
};

// Salesforce listener configuration parameters
type ListenerConfig record {
    string username;
    string password;
};

// Constants
const string CHANNEL_NAME = "/data/OpportunityChangeEvent";

configurable ListenerConfig salesforceListenerConfig = ?;
configurable OAuth2RefreshTokenGrantConfig salesforceOAuthConfig = ?;
configurable string salesforceBaseUrl = ?;

// Slack configuration parameters
// configurable string slackToken = ?;
// configurable string slackChannelName = ?;

listener sfdcListener:Listener sfdcEventListener = new ({
    username: salesforceListenerConfig.username,
    password: salesforceListenerConfig.password,
    channelName: CHANNEL_NAME
});

type OpportunityDetails record {
    string Name;
    string LastModifiedDate;
};

@display {label: "Salesforce Opportunity Update to Slack Channel Message"}
service sfdcListener:RecordService on sfdcEventListener {
    remote function onUpdate(sfdcListener:EventData payload) returns error? {
        io:print("onUpdate");
        string opportunityId = payload?.metadata?.recordId ?: "";
        string stageName = check payload.changedData.StageName;
        sfdc:Client sfdcClient = check new ({
            baseUrl: salesforceBaseUrl,
            auth: {
                clientId: salesforceOAuthConfig.clientId,
                clientSecret: salesforceOAuthConfig.clientSecret,
                refreshToken: salesforceOAuthConfig.refreshToken,
                refreshUrl: salesforceOAuthConfig.refreshUrl
            }
        });
        OpportunityDetails opportunityRecord = check sfdcClient->getById("Opportunity", opportunityId.toString(), ["Name", "LastModifiedDate"], OpportunityDetails);

        string message = string `Opportunity Updated | Opportunity Name : ${opportunityRecord.Name} | Opportunity Status: ${
            stageName} | Link: < ${salesforceBaseUrl}/${opportunityId} >`;

        // slack:Client slackClient = check new ({auth: {token: slackToken}});
        // _ = check slackClient->postMessage({
        //     channelName: slackChannelName,
        //     text: message
        // });
        io:print(message);
    }

    remote function onCreate(sfdcListener:EventData payload) returns error? {
        return;
    }

    remote function onDelete(sfdcListener:EventData payload) returns error? {
        return;
    }

    remote function onRestore(sfdcListener:EventData payload) returns error? {
        return;
    }
}

service /ignore on new http:Listener(8090) {
}
