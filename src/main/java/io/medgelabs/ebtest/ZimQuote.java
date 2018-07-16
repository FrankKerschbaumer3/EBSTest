package io.medgelabs.ebtest;

public class ZimQuote {

    private String message;

    public ZimQuote() { /* FOR JPA */ }

    public ZimQuote(String message) {
        this.message = message;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    @Override
    public String toString() {
        return "io.medgelabs.ebtest.ZimQuote{" +
            "message='" + message + '\'' +
            '}';
    }
}
