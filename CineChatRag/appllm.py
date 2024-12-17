from flask import Flask, render_template, request, jsonify
import pandas as pd
from langchain.docstore.document import Document
from langchain_openai import OpenAIEmbeddings
from langchain_chroma import Chroma
from langchain_openai import ChatOpenAI
from langchain_groq import ChatGroq
from langchain_community.query_constructors.chroma import ChromaTranslator
from langchain.retrievers.self_query.base import SelfQueryRetriever
from langchain.chains.query_constructor.schema import AttributeInfo

from langchain_core.prompts import ChatPromptTemplate

import os
import requests
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Initialize Flask app
app = Flask(__name__)

# Global variables for LLM and retriever
retriever = None
TMDB_API_KEY = os.getenv("TMDB_API_KEY")  # Make sure to load your API key from environment variables
TMDB_BASE_URL = "https://api.themoviedb.org/3"
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")  # Load OpenAI API key from environment variables

# Function to initialize the LLM and retriever
def initialize_retriever():
    global retriever

    # Load and preprocess the CSV file
    df = pd.read_csv("CineChatCSV_cleaned_new.csv")

    def combine_fields(row):
        summary = str(row.get('summary', ''))
        midpoint = len(summary) * 3 // 4
        half_summary = summary[:midpoint]
        content = f"Title: {row.get('title', '')}\nSummary: {half_summary}"
        return content

    df["content"] = df.apply(combine_fields, axis=1)

    documents = []
    for _, row in df.iterrows():
        metadata = {
            "title": row["title"],
            "director": row["director"],
            "actors": row["actors"],
            "genres": row["genres"],
            "plot": row["plot"],
            "id": row["id"],
            "imdb_id": row["imdb_id"],
            "poster_path": row["poster_path"],
            "year": row["year"],
            "rating": row["rating"],
        }
        doc = Document(page_content=row["content"], metadata=metadata)
        documents.append(doc)

    embeddings = OpenAIEmbeddings(model="text-embedding-3-large")
    #embeddings = HuggingFaceEmbeddings(model_name="sentence-transformers/all-mpnet-base-v2")
    #vectorstore = Chroma.from_documents(
    #    documents=documents,
    #    embedding=embeddings,
    #    persist_directory="movie_vectorstore5openai",
    #    ids=[doc.metadata["id"] for doc in documents],
    #    #use_jsonb=True
    #)

    def load_vectorstore(persist_directory="movie_vectorstore5openai"):
        return Chroma(persist_directory=persist_directory, embedding_function=embeddings)

    vectorstore = load_vectorstore()

    metadata_field_info = [
        AttributeInfo(
            name="title",
            description='The title of the movie (quoted, e.g., "Inception").',
            type="string"
        ),
        AttributeInfo(
            name="director",
            description='The director of the movie (quoted, e.g., "Christopher Nolan").',
            type="string"
        ),
        AttributeInfo(
            name="actors",
            description='The actors in the movie (quoted, e.g., "Leonardo DiCaprio, Joseph Gordon-Levitt").',
            type="string"
        ),
        AttributeInfo(
            name="genres",
            description=(
                'The genres of the movie (quoted, e.g., "Action, Sci-Fi, Thriller, Romance, Comedy, Drama, '
                'Horror, Fantasy, Mystery, Adventure, Animation, Biography, Crime, Family, Historical, '
                'Musical, Sports, War, Western").'
            ),
            type="string"
        ),
        AttributeInfo(
            name="year",
            description='The year the movie was released (quoted, e.g., "2010").',
            type="string"
        ),
        AttributeInfo(
            name="rating",
            description='The rating of the movie (quoted, e.g., "8.8").',
            type="string"
        ),
    ]


    document_content_description = "Brief summary of a movie"

    llm = ChatOpenAI(temperature=0, model="gpt-4o")
    #llm = ChatGroq(model="mixtral-8x7b-32768")
    retriever = SelfQueryRetriever.from_llm(
        llm=llm,
        vectorstore=vectorstore,
        document_contents=document_content_description,
        metadata_field_info=metadata_field_info,
        structured_query_translator=ChromaTranslator(),
        use_original_query=True,
        verbose=True,
    )


def call_groq_llm(query, movie_titles):
    system = """You are a movie recommendation assistant. 
    You have been asked to evaluate a movie recommendation according to question and retrieved movie titles.
    If not enough movie titles are retrieved, you can recommend movies based on the user question.
    Give a response so that this response will directly be shown to the user in the chatbot. Also the query comes from the user in the chatbot.
    Do not things like sure, absolutely etc. indicating that this server uses you as gpt because this response will be directly shown to the user.
    """
    grade_prompt = ChatPromptTemplate.from_messages(
    [
        ("system", system),
        ("human", "Retrieved Movie Titles: \n\n {movie_titles} \n\n User question: {question}"),
    ]
)
    llm = ChatGroq(model="mixtral-8x7b-32768")
    last_llm = grade_prompt | llm
    
    response = last_llm.invoke({"movie_titles": movie_titles, "question": query})

    return response.content





# Initialize retriever during app startup
initialize_retriever()

@app.route("/")
def index():
    return render_template('chat.html')

@app.route("/get", methods=["GET", "POST"])
def chat():
    msg = request.form["msg"]
    response = get_chat_response(msg.title())
    return response

# Function to get movie details (including rating and summary) from TMDb by IMDb ID
def get_movie_details(imdb_id):
    url = f"{TMDB_BASE_URL}/find/{imdb_id}?api_key={TMDB_API_KEY}&external_source=imdb_id"
    response = requests.get(url)

    if response.status_code == 200:
        data = response.json()
        if "movie_results" in data and len(data["movie_results"]) > 0:
            movie_id = data["movie_results"][0]["id"]
            movie_details_url = f"{TMDB_BASE_URL}/movie/{movie_id}?api_key={TMDB_API_KEY}"
            movie_details_response = requests.get(movie_details_url)
            if movie_details_response.status_code == 200:
                movie_data = movie_details_response.json()
                rating = movie_data.get("vote_average", 0)
                summary = movie_data.get("overview", "No summary available.")
                release_date = movie_data.get("release_date", "")
                year = release_date[:4] if release_date else "Unknown"
                return rating, summary, year
            
    else:
        print(f"Error: {response.status_code}, {response.text}")

    return None, "No summary available.", "Unknown"

# Modified function to get chat response
def get_chat_response(text):
    print("query: " + text)
    global retriever
    movie_details = []
    movie_titles = []
    try:
        results = retriever.invoke(text)        # Invoke the retriever with the user query
        #print("results: " + str(results))
              
        for doc in results:
            rating, summary, year = get_movie_details(doc.metadata['imdb_id'])
            movie_titles.append(doc.metadata["title"])
            movie_details.append({
                "title": doc.metadata["title"],
                "poster_url": f"https://image.tmdb.org/t/p/w500/{doc.metadata['poster_path']}",
                "rating": rating,
                "summary": summary,
                "year": year,
                "genre": doc.metadata.get("genres", "Unknown"),
                "actors": ", ".join(doc.metadata.get("actors", "").split(",")[:3])
            })
        gpt_response = call_groq_llm(text, movie_titles)
        response = {"gpt_response": gpt_response, "movies": movie_details}
    except Exception as e:
        print("exception: " + str(e))
        gpt_response = call_groq_llm(text, movie_titles)
        response = {"gpt_response": gpt_response, "movies": movie_details}

    return jsonify(response)

if __name__ == '__main__':
    port = int(os.environ.get("PORT", 5000))
    app.run(host="0.0.0.0", port=port)

# %%
