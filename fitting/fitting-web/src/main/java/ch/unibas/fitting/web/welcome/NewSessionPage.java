package ch.unibas.fitting.web.welcome;

import ch.unibas.fitting.web.application.IUserDirectory;
import ch.unibas.fitting.web.web.WizardPage;
import org.apache.wicket.markup.html.form.Button;
import org.apache.wicket.markup.html.form.Form;
import org.apache.wicket.markup.html.form.RequiredTextField;
import org.apache.wicket.markup.html.form.TextField;
import org.apache.wicket.markup.html.panel.FeedbackPanel;
import org.apache.wicket.model.PropertyModel;
import org.apache.wicket.validation.IValidatable;
import org.apache.wicket.validation.IValidator;
import org.apache.wicket.validation.ValidationError;
import org.apache.wicket.validation.validator.StringValidator;

import javax.inject.Inject;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Created by martin on 04.06.2016.
 */
public class NewSessionPage extends WizardPage {

    @Inject
    private IUserDirectory _userDir;

    private String username;

    public NewSessionPage() {

        if (session().hasUserName()) {
            setResponsePage(WelcomePage.class);
        }

        Form form = new Form("form");

        RequiredTextField<String> field = new RequiredTextField<String>("username", new PropertyModel<>(this, "username"));
        field.add((IValidator<String>) validate -> {
            Pattern pattern = Pattern.compile("\\s");
            Matcher matcher = pattern.matcher(validate.getValue());
            boolean found = matcher.find();
            if (found) {
                validate.error(new ValidationError("whitespaces are not allowed in username"));
            }
        });
        form.add(field);

        form.add(new Button("start") {
            @Override
            public void onSubmit() {
                if (isValid()) {
                    _userDir.createUserdir(username);
                    session().setUsername(username);
                    setResponsePage(WelcomePage.class);
                } else {
                    Logger.debug("Form not valid");
                }
            }
        });

        add(form);

        add(new FeedbackPanel("feedback"));
    }
}