import streamlit as st
import pyodbc
import pandas as pd
import pyodbc
import os
from dotenv import load_dotenv
 
# Load env variables
load_dotenv()
 
# Read values
driver = os.getenv("DB_DRIVER")
server = os.getenv("DB_SERVER")
database = os.getenv("DB_DATABASE")
uid = os.getenv("DB_UID")
pwd = os.getenv("DB_PWD")
 
# Connection
conn = pyodbc.connect(
    f"DRIVER={{{driver}}};"
    f"SERVER={server};"
    f"DATABASE={database};"
    f"UID={uid};"
    f"PWD={pwd}"
)
cursor=conn.cursor()
st.set_page_config(
    page_title="Service Management System",
)
 
st.title("Service Management System")
tab1, tab2, tab3, tab4= st.tabs(["View Tables","Insert an Asset","Analytics","New Query"])
 
# TAB 2: Insert a new asset
# Allows user to add a new asset linked to a specific customer
with tab2:
    st.header("Add asset")
    cust_id = st.number_input(
    "Enter customer ID",min_value=1,step=1,format="%d"
    )
    asset_name=st.text_input("Enter Asset name")
    asset_type=st.text_input("Enter Asset type")
    if st.button("Add Asset"):
        cursor.execute(
            "INSERT INTO Assets(customer_id,asset_name,asset_type) VALUES(?,?,?)", cust_id,asset_name,asset_type
        )
        conn.commit()
        st.success("Asset added!")
 
# TAB 3: Analytics (Technician workload)
# Shows number of work orders assigned to each technician using GROUP BY
with tab3:
    st.header( "Technician workload")
    query="""SELECT t.name, COUNT(w.work_order_id) AS total_tasks FROM Technicians t
    LEFT JOIN WorkOrders w
    ON t.technician_id=w.technician_id
    GROUP BY t.name """
    df=pd.read_sql(query,conn)
    st.dataframe(df)
 
# TAB 1: View all tables in the database
# Displays complete data from Customers, Assets, Technicians, ServiceRequests, and WorkOrders
with tab1:
    st.header("All Tables Data")
 
    # Customers
    st.subheader("Customers")
    df1 = pd.read_sql("SELECT * FROM Customers", conn)
    st.dataframe(df1)
 
    # Assets
    st.subheader("Assets")
    df2 = pd.read_sql("SELECT * FROM Assets", conn)
    st.dataframe(df2)
 
    # Technicians
    st.subheader("Technicians")
    df3 = pd.read_sql("SELECT * FROM Technicians", conn)
    st.dataframe(df3)
 
    # Service Requests
    st.subheader("Service Requests")
    df4 = pd.read_sql("SELECT * FROM ServiceRequests", conn)
    st.dataframe(df4)
 
    # Work Orders
    st.subheader("Work Orders")
    df5 = pd.read_sql("SELECT * FROM WorkOrders", conn)
    st.dataframe(df5)
 
 
# TAB 4: Run custom SQL queries
# Lets user manually input SELECT queries and view results dynamically
with tab4:
    st.header("Run Custom SQL Query")
 
    query = st.text_area("Enter SQL Query")
 
    if st.button("Execute"):
        if query.lower().startswith("select"):
            df = pd.read_sql(query, conn)
            st.dataframe(df)
        else:
            st.warning("Only SELECT queries allowed")
 
