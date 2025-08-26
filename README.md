A reproducible machine learning project that predicts customer churn using logistic regression. Data is stored in **MySQL**, analyzed with **Python**, and prepared for visualization in **Tableau**.  

---

## Project Overview
Customer churn is a critical business problem; retaining existing customers is often more cost-effective than acquiring new ones.  
This project demonstrates how to:
- Ingest and clean churn data in **MySQL**  

---

## Tools & Technologies
- **Python 3.12** (pandas, scikit-learn, mysql-connector, python-dotenv)  
- **MySQL** for relational data storage  
- **Tableau Public** for interactive dashboards  
- **Jupyter Notebook** for modeling and analysis  
- **GitHub** for version control and sharing  

---

## Project Structure

churn-prediction/  
├── data/ # Local datasets  
│ └── Telco-Customer-Churn.csv # Public Kaggle Dataset  
├── notebooks/  
│ └── churn_regression.ipynb # Main notebook with workflow   
├── scripts/  
│ └── load_csv.sh  
├── sql/  
│ ├── archive/  
│ │ └── telco_churn_database.sql  
│ ├── 00_schema.sql  
│ └── 01_post_load_transformations.sql  
├── .env.example # Example database credentials    
├── .gitattributes # Line ending normalization   
├── .gitignore # Ignores secrets, data, caches  
├── environment.yml # Conda environment configuration  
├── README.md  
├── requirements.txt # Minimal dependencies  
└── requirements-lock.txt # Fully pinned dependencies 


---

## ⚙️ Setup

### 1. Clone the repository
```bash
git clone https://github.com/jbrdge/churn-prediction.git
cd churn-prediction

2. Configure environment variables

Copy the example file and update with your MySQL credentials:

cp .env.example .env

3. Install dependencies

Using pip

python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

Using conda

conda env create -f environment.yml
conda activate churn-env

Running the Notebook

    Start Jupyter:

    jupyter notebook

    Open notebooks/churn_logreg_mysql.ipynb.

    Run cells top-to-bottom:

        Connects to MySQL

        Loads churn data


Visualization in Tableau

Import either:

    The MySQL table (customers_clean with churn_probability), or

    The CSV export (churn_predictions.csv).

Example dashboards:

    High-risk customers by contract type

    Churn probability by tenure

    Revenue at risk (MonthlyCharges * churn_probability)

Security

    Credentials are stored in .env (excluded from git).

    .env.example is provided as a template.

    Database passwords are never exposed in the notebook.


About
Customer Churn Prediction — an end-to-end data project demonstrating SQL integration, machine learning, and visualization best practices.



