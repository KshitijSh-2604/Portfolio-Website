import os
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from fastapi import APIRouter, HTTPException, Body
from pydantic import BaseModel, EmailStr

router = APIRouter(prefix="/contact", tags=["contact"])

class ContactForm(BaseModel):
    name: str
    email: EmailStr
    subject: str
    message: str

@router.post("")
async def send_contact_message(form: ContactForm):
    # For now, we simulate sending an email.
    # To enable real emails, set the SMTP_EMAIL and SMTP_PASSWORD in .env
    smtp_email = os.getenv("SMTP_EMAIL")
    smtp_password = os.getenv("SMTP_PASSWORD")
    target_email = "kshitij466e@gmail.com"

    print(f"Contact form submitted: {form.dict()}")

    if not smtp_email or not smtp_password:
        return {"status": "success", "message": "Simulated: Message received and logged."}

    try:
        msg = MIMEMultipart()
        msg['From'] = smtp_email
        msg['To'] = target_email
        msg['Subject'] = f"Portfolio Message: {form.subject}"

        body = f"Name: {form.name}\nEmail: {form.email}\n\nMessage:\n{form.message}"
        msg.attach(MIMEText(body, 'plain'))

        # Use Gmail SMTP with SSL on Port 465
        server = smtplib.SMTP_SSL('smtp.gmail.com', 465)
        server.login(smtp_email, smtp_password)
        server.send_message(msg)
        server.quit()

        return {"status": "success", "message": "Email sent successfully!"}
    except Exception as e:
        error_msg = str(e)
        print(f"SMTP error: {error_msg}")
        raise HTTPException(status_code=500, detail=f"Mail Error: {error_msg}")
