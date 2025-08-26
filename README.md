# Churn Prediction
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
