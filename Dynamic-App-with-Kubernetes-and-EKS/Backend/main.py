from fastapi import FastAPI, HTTPException, Depends, status, Request
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from typing import List, Optional, Union, Dict, Any
import uuid
from datetime import datetime
import os
import json
import logging
import traceback
import time
from sqlalchemy import create_engine, Column, Integer, String, Text, Boolean, ForeignKey, JSON, DateTime, func
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, relationship, Session

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger("survey-api")

app = FastAPI(title="Survey API")

# CORS configuration
origins = [
    "https://topsurvey.cloudspace-consulting.com",
    "http://localhost:3000",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Middleware for request logging
@app.middleware("http")
async def log_requests(request: Request, call_next):
    request_id = str(uuid.uuid4())
    start_time = time.time()
    
    # Log the request
    logger.info(f"Request {request_id} started: {request.method} {request.url.path}")
    
    # Process the request
    try:
        response = await call_next(request)
        process_time = time.time() - start_time
        logger.info(f"Request {request_id} completed: {response.status_code} in {process_time:.4f}s")
        return response
    except Exception as e:
        process_time = time.time() - start_time
        logger.error(f"Request {request_id} failed after {process_time:.4f}s: {str(e)}")
        logger.error(traceback.format_exc())
        raise

# Database configuration
DB_HOST = os.environ.get("DB_HOST")
DB_PORT = os.environ.get("DB_PORT", "5432")
DB_NAME = os.environ.get("DB_NAME", "surveys")
DB_USER = os.environ.get("DB_USER")
DB_PASSWORD = os.environ.get("DB_PASSWORD")

DATABASE_URL = f"postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# Database Models
class QuestionModel(Base):
    __tablename__ = "questions"
    
    id = Column(String, primary_key=True)
    survey_id = Column(String, ForeignKey("surveys.id", ondelete="CASCADE"))
    text = Column(Text, nullable=False)
    type = Column(String, nullable=False)
    required = Column(Boolean, default=False)
    options = Column(JSON, nullable=True)

class SurveyModel(Base):
    __tablename__ = "surveys"
    
    id = Column(String, primary_key=True)
    title = Column(String, nullable=False)
    description = Column(Text, nullable=True)
    created_at = Column(DateTime, default=func.now())
    responses = Column(Integer, default=0)
    
    questions = relationship("QuestionModel", cascade="all, delete-orphan")

class AnswerModel(Base):
    __tablename__ = "answers"
    
    id = Column(String, primary_key=True)
    response_id = Column(String, ForeignKey("responses.id", ondelete="CASCADE"))
    question_id = Column(String, ForeignKey("questions.id", ondelete="CASCADE"))
    answer = Column(JSON, nullable=True)

class ResponseModel(Base):
    __tablename__ = "responses"
    
    id = Column(String, primary_key=True)
    survey_id = Column(String, ForeignKey("surveys.id", ondelete="CASCADE"))
    created_at = Column(DateTime, default=func.now())
    
    answers = relationship("AnswerModel", cascade="all, delete-orphan")

# Create tables
Base.metadata.create_all(bind=engine)

# Dependency for database session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Pydantic Models
class QuestionBase(BaseModel):
    text: str
    type: str
    required: bool = False
    options: Optional[List[str]] = None

class Question(QuestionBase):
    id: str

class SurveyCreate(BaseModel):
    title: str
    description: Optional[str] = None
    questions: List[Question]

class Survey(SurveyCreate):
    id: str
    created_at: str
    responses: int = 0

class AnswerBase(BaseModel):
    question_id: str
    answer: Union[str, List[str]]

class SurveyResponseCreate(BaseModel):
    survey_id: str
    answers: List[AnswerBase]

class SurveyResponse(SurveyResponseCreate):
    id: str
    created_at: str

# Routes
@app.get("/")
async def root():
    """Root endpoint."""
    return {"message": "Welcome to the Survey API"}

@app.post("/surveys", response_model=Survey)
async def create_survey(survey: SurveyCreate, db: Session = Depends(get_db)):
    """Create a new survey."""
    try:
        logger.info(f"Creating new survey: {survey.title}")
        
        # Generate a unique ID and timestamp
        survey_id = str(uuid.uuid4())
        timestamp = datetime.now().isoformat()
        
        # Create survey in DB
        db_survey = SurveyModel(
            id=survey_id,
            title=survey.title,
            description=survey.description or "",
            created_at=datetime.now()
        )
        
        # Create questions
        for question in survey.questions:
            db_question = QuestionModel(
                id=question.id,
                survey_id=survey_id,
                text=question.text,
                type=question.type,
                required=question.required,
                options=question.options
            )
            db_survey.questions.append(db_question)
        
        db.add(db_survey)
        db.commit()
        
        # Prepare response
        survey_data = {
            "id": survey_id,
            "title": survey.title,
            "description": survey.description or "",
            "questions": [q.model_dump() for q in survey.questions],
            "created_at": timestamp,
            "responses": 0
        }
        
        logger.info(f"Successfully created survey with ID: {survey_id}")
        
        return Survey(**survey_data)
    except Exception as e:
        db.rollback()
        logger.error(f"Error creating survey: {str(e)}")
        logger.error(traceback.format_exc())
        raise HTTPException(status_code=500, detail=f"Error creating survey: {str(e)}")

@app.get("/surveys", response_model=List[Survey])
async def list_surveys(db: Session = Depends(get_db)):
    """List all surveys."""
    try:
        logger.info("Fetching all surveys")
        db_surveys = db.query(SurveyModel).all()
        
        surveys = []
        for db_survey in db_surveys:
            questions = []
            for q in db_survey.questions:
                questions.append({
                    "id": q.id,
                    "text": q.text,
                    "type": q.type,
                    "required": q.required,
                    "options": q.options
                })
            
            surveys.append({
                "id": db_survey.id,
                "title": db_survey.title,
                "description": db_survey.description,
                "created_at": db_survey.created_at.isoformat(),
                "responses": db_survey.responses,
                "questions": questions
            })
        
        logger.info(f"Found {len(surveys)} surveys")
        return surveys
    except Exception as e:
        logger.error(f"Error listing surveys: {str(e)}")
        logger.error(traceback.format_exc())
        raise HTTPException(status_code=500, detail=f"Error listing surveys: {str(e)}")

@app.get("/surveys/{survey_id}", response_model=Survey)
async def get_survey(survey_id: str, db: Session = Depends(get_db)):
    """Get a specific survey by ID."""
    try:
        logger.info(f"Fetching survey with ID: {survey_id}")
        db_survey = db.query(SurveyModel).filter(SurveyModel.id == survey_id).first()
        
        if not db_survey:
            logger.warning(f"Survey not found with ID: {survey_id}")
            raise HTTPException(status_code=404, detail="Survey not found")
        
        questions = []
        for q in db_survey.questions:
            questions.append({
                "id": q.id,
                "text": q.text,
                "type": q.type,
                "required": q.required,
                "options": q.options
            })
        
        survey = {
            "id": db_survey.id,
            "title": db_survey.title,
            "description": db_survey.description,
            "created_at": db_survey.created_at.isoformat(),
            "responses": db_survey.responses,
            "questions": questions
        }
        
        logger.info(f"Successfully retrieved survey: {survey_id}")
        return survey
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error retrieving survey {survey_id}: {str(e)}")
        logger.error(traceback.format_exc())
        raise HTTPException(status_code=500, detail=f"Error retrieving survey: {str(e)}")

@app.post("/surveys/{survey_id}/responses", response_model=SurveyResponse)
async def submit_response(
    survey_id: str, 
    response_data: SurveyResponseCreate, 
    db: Session = Depends(get_db)
):
    """Submit a response to a survey."""
    try:
        logger.info(f"Submitting response for survey ID: {survey_id}")
        
        # Verify survey exists
        db_survey = db.query(SurveyModel).filter(SurveyModel.id == survey_id).first()
        
        if not db_survey:
            logger.warning(f"Survey not found with ID: {survey_id}")
            raise HTTPException(status_code=404, detail="Survey not found")
        
        # Generate response ID and timestamp
        response_id = str(uuid.uuid4())
        timestamp = datetime.now().isoformat()
        
        # Create response
        db_response = ResponseModel(
            id=response_id,
            survey_id=survey_id,
            created_at=datetime.now()
        )
        
        # Add answers
        for answer in response_data.answers:
            db_answer = AnswerModel(
                id=str(uuid.uuid4()),
                response_id=response_id,
                question_id=answer.question_id,
                answer=answer.answer
            )
            db_response.answers.append(db_answer)
        
        db.add(db_response)
        
        # Update survey response count
        db_survey.responses += 1
        
        db.commit()
        
        # Prepare response data
        response_item = {
            "id": response_id,
            "survey_id": survey_id,
            "answers": [a.model_dump() for a in response_data.answers],
            "created_at": timestamp
        }
        
        logger.info(f"Successfully submitted response {response_id} for survey {survey_id}")
        
        return SurveyResponse(**response_item)
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        logger.error(f"Error submitting response: {str(e)}")
        logger.error(traceback.format_exc())
        raise HTTPException(status_code=500, detail=f"Error submitting response: {str(e)}")

@app.get("/surveys/{survey_id}/responses", response_model=List[SurveyResponse])
async def get_survey_responses(
    survey_id: str, 
    db: Session = Depends(get_db)
):
    """Get all responses for a specific survey."""
    try:
        logger.info(f"Fetching responses for survey ID: {survey_id}")
        
        # Verify survey exists
        db_survey = db.query(SurveyModel).filter(SurveyModel.id == survey_id).first()
        
        if not db_survey:
            logger.warning(f"Survey not found with ID: {survey_id}")
            raise HTTPException(status_code=404, detail="Survey not found")
        
        # Get responses
        db_responses = db.query(ResponseModel).filter(ResponseModel.survey_id == survey_id).all()
        
        responses = []
        for db_response in db_responses:
            answers = []
            for a in db_response.answers:
                answers.append({
                    "question_id": a.question_id,
                    "answer": a.answer
                })
            
            responses.append({
                "id": db_response.id,
                "survey_id": db_response.survey_id,
                "answers": answers,
                "created_at": db_response.created_at.isoformat()
            })
        
        logger.info(f"Found {len(responses)} responses for survey {survey_id}")
        
        return responses
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error retrieving responses for survey {survey_id}: {str(e)}")
        logger.error(traceback.format_exc())
        raise HTTPException(status_code=500, detail=f"Error retrieving responses: {str(e)}")

@app.get("/health", status_code=status.HTTP_200_OK)
async def health_check():
    """Health check endpoint for ALB."""
    logger.info("Health check requested")
    return {"message": "Service is healthy"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=80, reload=True)