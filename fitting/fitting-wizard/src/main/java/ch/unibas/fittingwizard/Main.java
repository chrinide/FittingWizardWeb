/*
 * Copyright (c) 2015, Florent Hedin, Markus Meuwly, and the University of Basel
 * All rights reserved.
 *
 * The 3-clause BSD license is applied to this software.
 * see LICENSE.txt
 *
 */
package ch.unibas.fittingwizard;

import javafx.application.Application;

/**
 * User: mhelmer
 * Date: 05.12.13
 * Time: 10:03
 */
public class Main {

    public static void main(String[] args) {

        String OS = System.getProperty("os.name").toLowerCase().trim();

        if (OS.equals("macosx")) {
            if (System.getProperty("java.version").startsWith("1.8.") == false) {
                fixOsxHeadlessException();
            }
        }

        /**
         * Create the GUI by passing WizardApplication to JAVAFX launcher
         */
        Application.launch(WizardApplication.class, args);
    }

    /**
     * This fixes the HeadlesseException encountered on OSX.
     * According to the JavaFX jira, this will be fixed with Java 8.
     * @see <a href="https://forums.oracle.com/thread/2469920">Oracle forum</a>
     * @see <a href="http://javafx-jira.kenai.com/browse/RT-20784">JavaFX jira issue</a>
     */
    private static void fixOsxHeadlessException() {
        System.out.println("---> Applying HeadlessException fix for OSX.");
        // LAST POST ON
        // http://stackoverflow.com/questions/15320915/javafx-screencapture-headless-exception-on-osx
        System.setProperty("javafx.macosx.embedded", "true");
        java.awt.Toolkit.getDefaultToolkit();
    }
}
