/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package dao;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
/**
 *
 * @author Asus
 */
public class DBConnection {

    private static final String DEFAULT_URL = "jdbc:mysql://localhost:3306/sharehub_db";
    private static final String DEFAULT_USER = "root";
    private static final String DEFAULT_PASSWORD = "";

    public static Connection getConnection() {
        Connection conn = null;
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            conn = DriverManager.getConnection(
                    config("SHAREHUB_DB_URL", "sharehub.db.url", DEFAULT_URL),
                    config("SHAREHUB_DB_USER", "sharehub.db.user", DEFAULT_USER),
                    config("SHAREHUB_DB_PASSWORD", "sharehub.db.password", DEFAULT_PASSWORD));
            System.out.println("Database connected successfully!");
        } catch (ClassNotFoundException | SQLException e) {
            System.out.println("Database connection failed!");
            e.printStackTrace();
        }
        return conn;
    }

    private static String config(String envName, String propertyName, String fallback) {
        String value = System.getenv(envName);
        if (value != null && !value.trim().isEmpty()) {
            return value.trim();
        }
        value = System.getProperty(propertyName);
        if (value != null && !value.trim().isEmpty()) {
            return value.trim();
        }
        return fallback;
    }
}
