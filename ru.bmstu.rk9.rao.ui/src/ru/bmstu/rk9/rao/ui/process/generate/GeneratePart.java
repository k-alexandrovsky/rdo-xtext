package ru.bmstu.rk9.rao.ui.process.generate;

import java.beans.PropertyChangeEvent;
import java.util.List;

import org.eclipse.draw2d.IFigure;
import org.eclipse.gef.EditPolicy;

import ru.bmstu.rk9.rao.ui.process.Node;
import ru.bmstu.rk9.rao.ui.process.ProcessDeletePolicy;
import ru.bmstu.rk9.rao.ui.process.ProcessEditPart;

public class GeneratePart extends ProcessEditPart {

	@Override
	protected IFigure createFigure() {
		IFigure figure = new GenerateFigure();
		return figure;
	}

	@Override
	protected void createEditPolicies() {
		installEditPolicy(EditPolicy.COMPONENT_ROLE, new ProcessDeletePolicy());
	}

	@Override
	protected void refreshVisuals() {
		GenerateFigure figure = (GenerateFigure) getFigure();
		Generate model = (Generate) getModel();

		figure.setLayout(model.getLayout());
	}

	@Override
	public List<Node> getModelChildren() {
		return ((Generate) getModel()).getChildren();
	}

	@Override
	public void propertyChange(PropertyChangeEvent evt) {
		if (evt.getPropertyName().equals(Node.PROPERTY_LAYOUT))
			refreshVisuals();
	}
}
