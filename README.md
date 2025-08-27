# Customer Churn Prediction

An end-to-end workflow for predicting customer churn. Data is ingested and cleaned in **MySQL**, modeled in **Python**, and prepared for visualization in **Tableau**.

---

## Project Overview

Customer churn is a critical business problem. Retaining customers is generally more cost-effective than acquiring new ones.  

This project shows how to:
- Load and clean data in a relational database
- Engineer features in SQL
- Train and evaluate a logistic regression model in Python

---

## Tools & Technologies

- **Python 3.12**: pandas, scikit-learn, mysql-connector, python-dotenv  
- **MySQL**: schema design, cleaning, feature engineering  
- **Tableau Public**: visualization of churn risk and revenue impact  
- **Jupyter Notebook**: documentation and modeling environment  
- **GitHub**: version control and reproducibility  

---

## Dataset
https://www.kaggle.com/datasets/blastchar/telco-customer-churn  

### Context
The data set includes information about:  
  
    Customers who left within the last month – the column is called Churn  
    Services that each customer has signed up for – phone, multiple lines, internet, online security, online backup, device protection, tech support, and streaming TV and movies  
    Customer account information – how long they’ve been a customer, contract, payment method, paperless billing, monthly charges, and total charges  
    Demographic info about customers – gender, age range, and if they have partners and dependents  


---

## Project Structure

churn-prediction/  
├── data/  
│ └── Telco-Customer-Churn.csv  
├── notebooks/  
│ └── churn_regression.ipynb  
├── scripts/  
│ └── load_csv.sh  
├── sql/  
│ ├── archive/  
│ │ └── telco_churn_database.sql  
│ ├── 00_schema.sql  
│ └── 01_post_load_transformations.sql  
├── .env.example  
├── .gitignore  
├── environment.yml  
├── requirements.txt  
├── requirements-lock.txt  
└── README.md  


## Setup

### 1. Clone the repository
```bash
git clone https://github.com/jbrdge/churn-prediction.git
cd churn-prediction
```

### 2. Configure environment variables
```bash
cp .env.example .env
# edit .env with your MySQL credentials
```

### 3. Install dependencies
#### Using pip
```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

#### Using conda
```bash
conda env create -f environment.yml
conda activate churn-env
```


### Database Setup (prerequisite)
Before running the notebook, prepare the database:

1. Create schema and customers table:
   ```bash
   mysql -u churn -p < sql/00_schema.sql
   ```

2. Load the raw churn dataset into MySQL:
   ```bash
   bash scripts/load_csv.sh
   ```

3. Run post-load transformations to build the clean table:
   ```bash
   mysql -u churn -p churn_project < sql/01_post_load_transformations.sql
   
4. Optional: SQL Sanity Checks and Baseline Scoring

    You can run additional queries to sanity-check the data and create a simple SQL-only churn score:

    ```bash
    mysql -u churn -p churn_project < sql/02_sanity_checks_and_baseline.sql
    ```

### Troubleshooting
```
ERROR 3948 (42000) at line 2: Loading local data is disabled; this must be enabled on both the client and server sides
```
To fix this error run:
```bash
sudo mysql -e "SHOW VARIABLES LIKE 'local_infile';"
```
You may see
```
+---------------+-------+
| Variable_name | Value |
+---------------+-------+
| local_infile  | OFF   |
+---------------+-------+
```
Then run
```bash
sudo mysql -e "SET GLOBAL local_infile = 1;"
```
Check:
```bash
sudo mysql -e "SHOW VARIABLES LIKE 'local_infile';"
```
```
+---------------+-------+
| Variable_name | Value |
+---------------+-------+
| local_infile  | ON   |
+---------------+-------+
```