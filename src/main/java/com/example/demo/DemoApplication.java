package com.example.demo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

@SpringBootApplication
public class DemoApplication {
    public static void main(String[] args) {
        SpringApplication.run(DemoApplication.class, args);
    }
}

@RestController
class BadController {

    // ❌ Hardcoded database credentials (Security Issue)
    private static final String DB_URL = "jdbc:mysql://localhost:3306/mydb";
    private static final String DB_USER = "admin";
    private static final String DB_PASSWORD = "password123"; // 🔴 SonarQube will flag this!

    @GetMapping("/greet")
    public String greet(@RequestParam String name) {
        // ❌ Possible NullPointerException (Bug)
        if (name.equals("admin")) { // 🔴 `name` could be null, causing an NPE!
            return "Hello, Admin!";
        }
        return "Hello, " + name;
    }

    @GetMapping("/connect-db")
    public String connectToDatabase() {
        Connection conn = null;
        try {
            // ❌ Not closing the database connection (Resource Leak - Code Smell)
            conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
            return "Connected to Database!";
        } catch (SQLException e) {
            // ❌ Catching generic Exception (Bad Practice)
            System.out.println("Something went wrong!");
            return "Failed to connect!";
        }
    }
}
