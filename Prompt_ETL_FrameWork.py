# Prompt Based ETL Framework:
from langchain_groq import ChatGroq
from pandasai import SmartDataframe
import pandas as pd

llm_model = ChatGroq(
    model_name ="gemma2-9b-it", # You Can Select Any Foundation AI Model
    temperature = 0,
    groq_api_key = "MY_LLM_API_KEY" # Get API KEY From GROQ Website
)

class PromptETL:
  def __init__(self):
    pass

  def getData(self,path):
    data = pd.read_csv(path)
    return data

  def getSmartData(self,df):
    smart_df = SmartDataframe(df,config = {"llm":llm_model})
    return smart_df

  def getTransformedData(self,data,etl_prompt):
    try:
      smart_df = self.getSmartData(df = data)
      res_df = smart_df.chat(etl_prompt)
      return res_df
    except Exception as e:
      return e
