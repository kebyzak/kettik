package main

import (
	"context"
	"crypto/tls"
	"fmt"
	"log"
	"mime"
	"net"
	"net/smtp"
	"os"
	"time"

	"kettik/internal/auth"
)

type smtpConfig struct{ host, port, user, pass, from string }

// codeSender mails codes over SMTP with STARTTLS when SMTP_HOST, SMTP_USER,
// SMTP_PASSWORD and SMTP_FROM are set, and prints them to the log otherwise (local dev).
func codeSender() auth.Sender {
	c := smtpConfig{
		host: os.Getenv("SMTP_HOST"),
		port: env("SMTP_PORT", "587"),
		user: os.Getenv("SMTP_USER"),
		pass: os.Getenv("SMTP_PASSWORD"),
		from: os.Getenv("SMTP_FROM"),
	}
	if c.host == "" || c.user == "" || c.pass == "" || c.from == "" {
		log.Print("SMTP_HOST/SMTP_USER/SMTP_PASSWORD/SMTP_FROM not all set: sign-in codes go to the log")
		return logCode
	}
	log.Printf("sign-in codes are mailed via %s:%s from %s", c.host, c.port, c.from)
	// shortcut: a free SMTP relay sending from a free mailbox address, so mail may land in spam; move to an own domain with SPF/DKIM before launch.
	return func(ctx context.Context, email, code string) error {
		return c.send(ctx, email, codeMessage(c.from, email, code))
	}
}

// to already passed auth's email check (no spaces or line breaks), so it is safe in a header.
func codeMessage(from, to, code string) []byte {
	subject := mime.QEncoding.Encode("utf-8", code+" — код для входа в Kettik")
	body := "Код для входа в Kettik: " + code + "\r\n" +
		"Код действует 10 минут.\r\n\r\n" +
		"Kettik-ке кіру коды: " + code + "\r\n" +
		"Код 10 минут бойы жарамды.\r\n\r\n" +
		"Если вы не входили в Kettik, просто проигнорируйте это письмо.\r\n"
	return []byte("From: Kettik <" + from + ">\r\n" +
		"To: " + to + "\r\n" +
		"Subject: " + subject + "\r\n" +
		"Date: " + time.Now().Format(time.RFC1123Z) + "\r\n" +
		"MIME-Version: 1.0\r\n" +
		"Content-Type: text/plain; charset=utf-8\r\n" +
		"Content-Transfer-Encoding: 8bit\r\n\r\n" + body)
}

// send is smtp.SendMail with a deadline, so a stuck relay cannot hang the request.
// STARTTLS is required: PlainAuth refuses to send the password without it.
func (s smtpConfig) send(ctx context.Context, to string, msg []byte) error {
	ctx, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()
	conn, err := (&net.Dialer{}).DialContext(ctx, "tcp", net.JoinHostPort(s.host, s.port))
	if err != nil {
		return err
	}
	defer conn.Close()
	deadline, _ := ctx.Deadline()
	if err := conn.SetDeadline(deadline); err != nil {
		return err
	}
	c, err := smtp.NewClient(conn, s.host)
	if err != nil {
		return err
	}
	defer c.Close()
	if err := c.StartTLS(&tls.Config{ServerName: s.host}); err != nil {
		return fmt.Errorf("smtp starttls: %w", err)
	}
	if err := c.Auth(smtp.PlainAuth("", s.user, s.pass, s.host)); err != nil {
		return fmt.Errorf("smtp auth: %w", err)
	}
	if err := c.Mail(s.from); err != nil {
		return fmt.Errorf("smtp from: %w", err)
	}
	if err := c.Rcpt(to); err != nil {
		return fmt.Errorf("smtp rcpt: %w", err)
	}
	w, err := c.Data()
	if err != nil {
		return err
	}
	if _, err := w.Write(msg); err != nil {
		return err
	}
	if err := w.Close(); err != nil {
		return fmt.Errorf("smtp data: %w", err)
	}
	return c.Quit()
}
