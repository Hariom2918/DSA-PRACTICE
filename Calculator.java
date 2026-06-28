import javax.swing.*;
import java.awt.*;
import java.awt.event.*;

class Calculator {

    public static void main(String[] args) {

        JFrame f = new JFrame("Calculator");

        f.setLayout(new FlowLayout());

        JTextField t1 = new JTextField(10);

        JTextField t2 = new JTextField(10);

        JButton add = new JButton("+");
        JButton sub = new JButton("-");
        JButton mul = new JButton("*");
        JButton div = new JButton("/");

        JLabel l = new JLabel("Result:");

        // Addition
        add.addActionListener(e -> {

            int a = Integer.parseInt(t1.getText());
            int b = Integer.parseInt(t2.getText());

            l.setText("Result: " + (a + b));
        });

        // Subtraction
        sub.addActionListener(e -> {

            int a = Integer.parseInt(t1.getText());
            int b = Integer.parseInt(t2.getText());

            l.setText("Result: " + (a - b));
        });

        // Multiplication
        mul.addActionListener(e -> {

            int a = Integer.parseInt(t1.getText());
            int b = Integer.parseInt(t2.getText());

            l.setText("Result: " + (a * b));
        });

        // Division
        div.addActionListener(e -> {

            int a = Integer.parseInt(t1.getText());
            int b = Integer.parseInt(t2.getText());

            l.setText("Result: " + (a / b));
        });

        f.add(new JLabel("First Number:"));
        f.add(t1);

        f.add(new JLabel("Second Number:"));
        f.add(t2);

        f.add(add);
        f.add(sub);
        f.add(mul);
        f.add(div);

        f.add(l);

        f.setSize(300,300);

        f.setVisible(true);

        f.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
    }
}