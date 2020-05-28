## Unit Testing

The package provides functions to perform unit tests against a blank CDM. The unit test framework assumes you have established an empty CDM and have populated the vocabulary tables. Additionally, it is highly recommended to index the vocabulary tables when executing the unit tests.

This Unit Testing part is not needed to execute the study this is for development purposes only.

### unit Test connection details
Create or add to the file `.Renviron` in the root of the package to hold the settings for connecting to the CDM for unit testing.
````
# --------------------------------
# ------ Unit Test DB ------------
# --------------------------------
UT_DBMS = "postgresql"
UT_DB_SERVER = "myserver/unittest"
UT_DB_PORT = 5432
UT_DB_USER = dbUserName
UT_DB_PASSWORD = anotherSuperSecretPassword
UT_CDM_SCHEMA = "cdm"
UT_COHORT_SCHEMA = "results"
UT_TEST_CASES_FILE_LOCATION = "<path_to_cloned_project>/DrugUtilization/inst/testCases"
UT_TEST_CASES_RESULTS_LOCATION = "<path_to_cloned_project>/DrugUtilization/testResults"
````

### Unit Test Definitions

Unit tests are defined as .JSON files and are located in the folder `inst/testCases`. The general structure is shown here:

````
{
    "cdm.person": [
        {
            "person_id":1,
            "gender_concept_id":8532,
            "year_of_birth":1999,
            "race_concept_id":0,
            "ethnicity_concept_id":0
        },
        {
            "person_id":2,
            "gender_concept_id":8507,
            "year_of_birth":1995,
            "race_concept_id":0,
            "ethnicity_concept_id":0
        }
    ],
    "cdm.observation_period" : [
        {
          "observation_period_id": 1,
          "person_id":1,
          "observation_period_start_date":"2000-01-01",
          "observation_period_end_date":"2001-01-01",
          "period_type_concept_id": 0
        },
        {
          "observation_period_id": 2,
          "person_id":2,
          "observation_period_start_date":"2000-01-01",
          "observation_period_end_date":"2001-01-01",
          "period_type_concept_id": 0
        }
    ],
    "cdm.drug_exposure": [
        {
          "drug_exposure_id": 1,
          "person_id":1,
          "drug_concept_id":40852223,
          "quantity": 30,
          "days_supply": 30,
          "drug_exposure_start_date":"2000-01-01",
          "drug_exposure_end_date":"2000-01-31",
          "drug_type_concept_id":0
        },
        {
          "drug_exposure_id": 2,
          "person_id":2,
          "drug_concept_id":40852223,
          "quantity": 30,
          "days_supply": 30,
          "drug_exposure_start_date":"2000-01-01",
          "drug_exposure_end_date":"2000-01-31",
          "drug_type_concept_id":0
        }
    ]
````

In the example above, we define 2 patients with an observation period (mandatory) and a single drug exposure for use in a test.

### Unit Test SQL

The .JSON files described above are processed and turned into SQL located in `inst/testCases/sql` by using the R script located in `extras/CreateUnitTestData.R`. The SQL is generated and designed to create the patients as defined in the .JSON files in a blank CDM.

Before using `extras/CreateUnitTestData.R` be sure to set the enviroment variable `UT_TEST_CASES_FILE_LOCATION` shown in the Installation section above and replace `<path_to_cloned_project>` with the file path where you cloned the project from GitHub.

### Unit Test Execution

Once the SQL files with the test cases are generated, we can execute the unit tests. To do this, create a blank CDM using the appropriate scripts found on https://github.com/OHDSI/CommonDataModel. Load in the vocabulary and index the vocabulary related tables.

Next, configure the `UT_*` settings as shown in the Installation section to provide a connection to a database that you plan to use for performing the unit tests. The account that is used for these unit tests will need to have read/write access to the CDM schema to create the test cases and full control over the results schema to execute the analysis and to remove tables after each test.

The file `extras/ExecuteUnitTests.R` is used to execute the unit tests against the unit test CDM. This script will take all of the SQL files in `inst/testCases/sql` and iteratively do the following:

- Create the data in the CDM as defined in the .SQL file
- Execute the DUS analysis for those patients in the test case
- Export the results and use the test case name as the `databaseName`
- Each test result is then exported to the file location defined in `UT_TEST_CASES_RESULTS_LOCATION`

Once complete, the process will then launch the results explorer app enabling you to review the test results. The database drop down will hold the name of each test case so you can review the results.