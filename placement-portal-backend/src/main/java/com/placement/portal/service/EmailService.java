package com.placement.portal.service;

import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
@Slf4j
public class EmailService {

    private final JavaMailSender mailSender;

    public void sendOtp(String toEmail, String otp) {
        String subject = "BMU Student Portal - Email Verification OTP";
        String htmlContent = "<div style=\"font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 10px;\">" +
                "<h2 style=\"color: #6366F1; text-align: center;\">BMU Placement Portal</h2>" +
                "<p>Hello,</p>" +
                "<p>Thank you for registering at the BMU Student Placement Portal. Please use the following One-Time Password (OTP) to verify your email address. This OTP is valid for 5 minutes:</p>" +
                "<div style=\"text-align: center; margin: 30px 0;\">" +
                "<span style=\"font-size: 32px; font-weight: bold; letter-spacing: 5px; color: #1e1b4b; background-color: #f3f4f6; padding: 10px 20px; border-radius: 5px;\">" + otp + "</span>" +
                "</div>" +
                "<p>If you did not request this verification, you can safely ignore this email.</p>" +
                "<br/>" +
                "<p>Best regards,</p>" +
                "<p><strong>BMU Placement Team</strong></p>" +
                "</div>";

        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");
            
            helper.setTo(toEmail);
            helper.setSubject(subject);
            helper.setText(htmlContent, true);
            
            mailSender.send(message);
            log.info("Verification OTP email sent successfully to {}", toEmail);
        } catch (Exception e) {
            log.error("Failed to send verification email to {}. Error: {}", toEmail, e.getMessage());
            log.info("============== OFFLINE DEV FALLBACK ==============");
            log.info("TO: {}", toEmail);
            log.info("OTP: {}", otp);
            log.info("==================================================");
        }
    }
}
