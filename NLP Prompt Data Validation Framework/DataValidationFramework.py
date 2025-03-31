from chatWithDB import get_gemini_response , query_db_from_gen_ai_response 
import sqlite3 
from reportlab.lib.pagesizes import letter
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle ,Paragraph ,Spacer ,Image 
from reportlab.lib.units import inch
from reportlab.lib import colors ,pagesizes
from reportlab.lib.styles import getSampleStyleSheet
import pandas as pd 

def get_table_object(db_data):
    # Convert DataFrame to a list of lists
    data_list = [db_data.columns.values.tolist()] + db_data.values.tolist()
    # Create a Table object
    table = Table(data_list)
    # Add style to the table
    style = TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.gray),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
        ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('BOTTOMPADDING', (0, 0), (-1, 0), 7),
        ('BACKGROUND', (0, 1), (-1, -1), colors.lightpink),
        ('GRID', (0, 0), (-1, -1), 1, colors.black),
    ])
    table.setStyle(style)
    return table 
# Tell GEN AI Model How will be the user prompt behaviour:
prompt = """
    You are an expert to convert english text into sql query. Also you are an expert to perform data validation between 2 datasets.
    \n You are very good at data quality checks and data validation testing.
    \n You are expert to analyze netflix movies and shows data .
    \n Only return sql query based on user prompt do not return any explanation. If you are not able to convert to sql query then return Not able to understand message.
    \n Database stores Netflix movies and shows information
   \n Database will have table named netflix_shows_stg and netflix_shows_prod. 
   \n Is user is providing same prompts then generate same queries. Do not give me different queries for same prompts.
   \n netflix_shows_stg table stores data from stage and netflix_shows_prod stores data from production environments.
    \n Both tables will have total 11 columns and columns are tbl_index,id,title,type,description,release_year,age_certification,runtime,imdb_id,imdb_score,imdb_votes.
    Each record of table talks about particular movie or show detail. type column stores whether it is movie of show.
    A user may ask for total how many rows are there in each table ,sql command will be like select count(*) from netflix_shows_stg.
    \n User will perform data validation testing between stage and production data to identify any data integrety issue in production. Stage data is tested and it should be considered as driving.
    \n User may ask different data analytics queries like which which show or movie is having high imdb score.
    \n User may ask different data quality queries like how many duplicates records or null values are present in each column.
    \n User may ask data validation queries like which shows are present in stage but not in production. User may also ask to compare stage and production data.
    """
conn = sqlite3.connect('netflix_db.db') 

# Create a PDF document
pdf_file = "datavalidationreport.pdf"
document = SimpleDocTemplate(pdf_file, pagesize=pagesizes.C4)


img = Image('Data-Quality.png') 
img.drawHeight = 2 * inch
img.drawWidth = 6 * inch 

# Build the PDF:
text = 'DATA VALIDATION AND QUALTY REPORT:' 
para = Paragraph(text,getSampleStyleSheet()['Title']) 
elements = []
elements.append(para) 
elements.append(Spacer(1, 0.2 * inch)) # Add some spaces
elements.append(img) 
elements.append(Spacer(1, 0.2 * inch)) # Add some spaces

# Traversing Each Prompts:
prompts_df = pd.read_csv('validation_prompts_template.csv')
for index,row in prompts_df.iterrows() :
    question = row['validation_prompt']
    generated_query = get_gemini_response(question,prompt).replace("```","").replace("sql","")
    db_data = query_db_from_gen_ai_response(ai_query=generated_query,conn=conn) 
    query = Paragraph('Query' + str(row['prompt_id']) + ':' + ' \n' + generated_query,getSampleStyleSheet()['Normal'])
    elements.append(query)
    elements.append(Spacer(1, 0.2 * inch)) # Add some spaces
    elements.append(Paragraph('OUTPUT:'))
    if db_data.shape[0] != 0:
        elements.append(get_table_object(db_data))
        elements.append(Spacer(1, 0.2 * inch)) # Add some spaces
    else:
        elements.append(Paragraph(text = 'No data returned'))
        elements.append(Spacer(1, 0.2 * inch)) # Add some spaces
document.build(elements)
print('PDF is generated')