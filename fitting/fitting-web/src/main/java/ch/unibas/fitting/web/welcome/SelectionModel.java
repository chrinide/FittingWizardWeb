package ch.unibas.fitting.web.welcome;

import java.util.Arrays;
import java.util.List;

public class SelectionModel {
    private String name;
    private Class type;

    public SelectionModel(String name, Class type) {
        this.name = name;
        this.type = type;
    }

    public Class getType() {
        return type;
    }

    @Override
    public String toString() {
        return name;
    }

    public static List<SelectionModel> createDefaultSelections() {
        return Arrays.asList(
                new SelectionModel("MTP Fit using Gaussian", ch.unibas.fitting.web.gaussian.Step1Page.class),
                new SelectionModel("LJ Fit using CHARMM", ch.unibas.fitting.web.ljfit.Step1Page.class)
        );
    }
}
