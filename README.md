## Predictive detection of RMA devices 

**John Ruiz**

### Executive summary

Let us start from the concept of RMA: RMA stands for Return Merchandise Authorization. It's a formal agreement between a seller (usually a retailer) and a customer that allows the return of a product.

In many businesses, the RMA process is something that could generate unexpected expenses since it generally involves the replacement of a product and the customer could have a bad experience when using the service or product. Specifically in our GPS tracking business, the RMA experience is very similar. I will focus on the world of GPS devices to predict when devices can go through the RMA process by exploring the malfunction warnings collected.

### Rationale
From a business stand point, it is imperative to keep all customers happy with the products we offer. Considering this is a GPS tracking company, the good performance of the devices installed in each vehicle is essential to fulfill this promise.

### Research Question

How can we predict whether or not a GPS device shows bad behavior to proactively initiate an RMA process and prevent customers from having a bad experience when tracking their vehicles?


### Data Sources

The analysis will be based on 3 different files consisting of:

- [devices_active.csv](data/devices_active.csv): This file consist of 2000 records containing information for active devices working as expected.
- [devices_rma.csv](data/devices_rma.csv): It consists of 647 records with devices processed as RMA. In order to mark those devices as RMA, this was necessary to perform a sequence of thoubleshooting steps.
- [troubleshooting_cases.xlsx](data/troubleshooting_cases.xlsx): This is a generated report from "Sales Force" platform where the registered cases are reported by our customers. Some cases are related to devices by including the ESN or IMEI.


### Attribute Information:

#### **devices_active.csv & devices_rma.csv structure**

*Those files contain the same structure*

- companyId: Internal identifier for the account related with the devices
- unitId: Device identifier
- imei: IMEI registered in the system for this devices
- esn: Serial number
- manufacturer: Name of the manufacturer
- unitType: Classification for the device
- version: Device model
- isRMA: Boolean indicating if device is marked as RMA
- liveAgeDays: Duration in days for the devices being active in the platform
- HDOPQuality: Average events received with HDOPQuality > 2
- ExcessiveEvents: Average events received at server level from device. This evaluates the - maximum events the device is supposed to transmit
- LowBattery: Average events received at server level identified as "low battery"
- IgnitionOnEventsAbnormal: When a device reports more than 50 times per day and the ignitions received is higher than 15% of total. This is an average value.
- PowerDisconnect: Average events received at server level identified as "power disconnected"
- LowSatellites: Average occurencies When this has being determined the amount of low satellites is present more than 15% of total events.
- DailyOdometerExceeded: Average accumulated distance (Odometer in miles) reported exceeding a distance considering average speed for a vehicle
- WirelessSignal: When the average signal strengh is lower than 10. This is an average.
- MaintenanceLimitExceeded: This is an event generated for devices where the manufacturer is "Calamp". Refers to an event generated when device is reporting the same event more than 100 times during a day. This is a average of occurrences for this event
- LateEvents: When the events arriving late to server is higher than 10% compared with the - total events. This is an average.
- CommLost: This is a percentage, validating when commLost events are greater than 10% of total events received
- DailyEngineHoursExceeded: When this is detected the engineHours reported are higher than 24 hours. This is an average of the engine hours reported


#### **troubleshooting_cases.xlsx**
*From this file, we are interested in counting the occurrencies of a device being reported in cases. We'll be looking for the totalCases.*

- PM Account ID: Identifier of this account over the internal company's platform manager
- IMEI / SN: Device's identification separated by comma. Using IMEI or SN as identifier
- Account Name: Name of the account in our platform
- Subject: Title for the case
- Case Number: Auto generated value from SalesForce identifying the case
- Status: Current status for the case
- Number of Devices Impacted: Devices with the same situation reported in the case
- Category: Classification for the case
- SubCategory: Subclassification for the case
- Return Status: Used to trace when devices must be returned to us. This shows the status of return
- Open: Boolean indicating when the case is opened
- Closed: Boolean indicator when the case is closed

### Methodology

1. Collect dataset from client databases including maintenance warnings generated per device.
2. Collect dataset from client databases including the list of devices marked as RMA including the maintenance warnings generated by those devices.
3. Export data from Sales Force including the cases related to devices.
4. Generate an unified dataset with the combination of the 3 mentioned above. The final dataset shows active devices, rma devices and the total cases reported by each device.
5. Lookup for missed data over the unified dataset and fill gaps accordingly. Disregards the unnecessary information.
6. Idenfity the baseline by using a Dummy Classifier to know what are the minimum performance expected over the trained model.
7. Perform a comparison of different classification models including: KNeighborsClassifier, DecisionTreeClassifier, SVC, LogisticRegression, One vs. Rest, Oversampling. Looking for the model with best performance.
8. Since RMA devices vs. active devices are imbalanced, we will include an "oversampling" technique into comparisons.


### Data Preparation

In order to prepare the data for analysis, I'll be generating a unique dataset from the 3 files mentioned above. The goal on this step is to join `devices_active.csv` and `devices_rma.csv` having the same structure. The resulting file contains the ESN and/or IMEI for each GPS unit.


#### Missed values for devices dataset

Once the `devices_active` and `devices_rma` dataset are concatenated, this is identified some missed `imei`. This is know internally the system could use ESN or IMEI as identifier for GPS Tracking devices. For this reason, we'll be filling those empty spaces with the ESN value.

![Missed values - heatmap](images/heatmap_before.png)

#### Re-evaluating missed values after cleanup

Once the missed IMEIs has being updated with the ESN, this is evaluated the missed values using a heatmap graph again:

![Missed values - heatmap](images/heatmap_after.png)

#### Complementing DataSet with cases reported by device

At this point, we have a clean dataset containing the identifier for each GPS devices on each record. Using this identifier, we went through the `troubleshooting_cases.xlsx` looking for occurences where the ESN or IMEI is present. By iterating this file, we are able to identify the `totalCases` reported in our cases platform per device. This is a good indicator of potentials failures detected historically for the device.

#### Proportion of RMA devices over the devices dataset

The following shows the data balancing for active vs devices processed as RMA. This is an imbalanced dataset.

![RMA Balance](images/dataset_balance.png)


#### Correlation between features included in dataset

We'll be removing some features with high correlation and the identifiers columns like: companyId, unitId, imei, esn. Manufacturer and unitType will be remove as this is correlated with version. The initial identifiers ESN/IMEI acomplished their purpose of getting the totalCases defined in our external troubleshooting file.

![Correlation](images/correlation_before.png)


#### Evaluating best model
 
![Comparison Table](images/table_comparison.png)

![Test Score comparison](images/test_score_comparison.png)

Based on the above results, the best model fitting the dataset provided is the `KNeighborsClassifier`. I'll be using this model to predict the target column `isRMA`.


### Feature Importance

![Feature Importance](images/feature_importance.png)

Based on the above graph, the following features are the most important when predicting isRMA (Top 4):

- liveAgeDays
- HDOPQuality
- IgnitionOnEventsAbnormal
- totalCases

The liveAgeDays is an indicator of natural wear and tear of devices. Over time, electronic components, vehicle vibration and other factors can affect GPS device performance. Considering this attribute, the company should review any replacement policies (Warranty) to avoid incurring in extra costs by assuming it.

Devices presenting worse HDOP quality are subject to replacement or installation review. When the GPS signal is not accurate enough, the customer could have a negative experience when tracking vehicle's location. This is a critical factor as shown in the above results.

When the Ignition On/Off appears with high frequency over reports received from devices, this is a negative sign of the device's performance. We could tackle this by evaluating devices where the ignition is NOT detected correctly, firmware with failures over GPS devices and others.

The totalCases column refers to the cases reported by customer when they need to escalate with our internal support team concerning any failure or concern with the device.

### Feature analysis

#### RMA average time to live
![RMA ttl](images/rma_ttl.png)

The `liveAgeDays` reflects the duration in days of the device's active state. For devices marked as RMA, this value is equivalent on average to `519 days`. This measure must be considered by the company to review the policies it offers to customers regarding device replacement.

#### What is the average live age in days per device version?
![RMA vs Version](images/rma_vs_version.png)

Devices version labeled as `2630 3G` is the most durable device in the GPS platform. Meanwhile the `TLP2` and `50MG` a lowest benefit for the company as the rate of live age (TTL) is lower meaning the failures are raising quickly once devices are installed. It is important for the company to use devices presenting lower or non rate of TTL. 


#### What is the version with worse HDOPQuality?
![Worse HDOP Quality](images/worse_hdop.png)

Based on the above graph the `TTU730 LTE A` presents the worse HDOP quality. This should be considered to use an alternative option of hardware as replacement for this version on replacements and new sales in order to avoid unpleasant customer experiences.

#### What is the model with major reported cases?
![By Total cases](images/by_totalcases.png)

The `4K` version is the model of devices getting major number of cases reportes through "Sales Force" followed by `88` series. The first one was identified as a recent implementation justifying the amount of cases that could be related to customer and internal trainings over the new version. 

#### What is the model presenting higher IgnitionOnEventsAbnormal?
![Abnormal Ignitions](images/abnormal_ignitions.png)

The `88` series presents the major number of abnormal IgnitionOn events with a high difference vs the next version (`4K`). This is relevant for customer's experience devices must be correctly installed and reporting correctly the Ignition On/Off events. This is suggested to revisit the installation procedure for `88` version and/or consider an alternative GPS device with similar capabilities.

## Findings

- The TTL (Live Age in days) average for a device being marked as RMA is `519 days`. It is an important meassure for the company to review the RMA policies.
- Devices like `TTU730 LTE A` and `VeoSphere` shows the worse HDOP Quality. This is one of the most relevant criteria triggering the RMA process.
- The device version labeled `88` present the major number of abnormal IgnitionOn events. This is important to identify the main reasons of this failure and/or the possibility to use a device with similar capabilities.
- KNeighborsClassifier was the best performing model to predict the isRMA classification.


## Next steps
As next steps to improve the accuracy of this model we could add more features to the dataset. It is possible to add more `Maintenance Warnings` related to unexpected behavior. This is commonly known when there are more cases such as when the latitude and longitud didn't change between reports.  Additionally, this could be important to include reasons of RMA in order to include major analysis beneficial for the company.

## Outline of project

The following is the notebook used to perform analysis over the data mentioned above:

[MaintenanceWarnings.ipynb](MaintenanceWarnings.ipynb)


### Contact and Further Information

**John Ruiz**\
Director of Software Engineering\
GPS Trackit Communications\
[www.gpstrackit.com](https://www.gpstrackit.com)\
Email: jruiz@gpstrackit.com


