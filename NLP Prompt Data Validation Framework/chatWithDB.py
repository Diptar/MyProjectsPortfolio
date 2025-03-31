import sqlite3 
import pandas as pd 
import google.generativeai as genai 
# Connect To Olympic DB :
conn = sqlite3.connect('netflix_db.db') 
# Google Gemini AI API Key:
api_key = "" # Provide API Key
genai.configure(api_key = api_key)

# Function To Load Gemini Model And Provide SQL Query As Response: 
def get_gemini_response(question,prompt): # Function will give me SQL query
    # Prompt: How model will behave like:
    # question: NLP text
    model = genai.GenerativeModel('gemini-2.0-flash')
    response = model.generate_content([question,prompt])
    return response.text 

# Query DB based of AI generated SQL: 
def query_db_from_gen_ai_response(ai_query,conn):
    data = pd.read_sql_query(ai_query,conn)
    return data 
