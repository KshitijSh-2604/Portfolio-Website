from pydantic import BaseModel, ConfigDict, Field
from pydantic.alias_generators import to_camel
from typing import List, Optional
from datetime import datetime

# Pydantic Models for Post
class PostBase(BaseModel):
    title: Optional[str] = None
    content: str
    images: List[str] = []
    video_url: Optional[str] = Field(None, alias="videoUrl")
    link: Optional[str] = None
    
    model_config = ConfigDict(
        populate_by_name=True
    )

class PostCreate(PostBase):
    pass

class PostOut(PostBase):
    id: int
    created_at: datetime = Field(validation_alias="created_at", serialization_alias="createdAt")
    updated_at: datetime = Field(validation_alias="updated_at", serialization_alias="updatedAt")

    model_config = ConfigDict(
        populate_by_name=True,
        from_attributes=True
    )

# Pydantic Models for Auth
class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    username: Optional[str] = None
