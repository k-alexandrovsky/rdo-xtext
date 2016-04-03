package ru.bmstu.rk9.rao.ui.process;

import org.eclipse.swt.graphics.RGB;

public abstract class NodeWithProbability extends NodeWithProperty {

	private static final long serialVersionUID = 1;

	public static final String PROPERTY_PROBABILITY = "NodeProbability";

	protected String probability = "0.5";

	public NodeWithProbability(RGB foregroundColor) {
		super(foregroundColor);
	}

	public void setProbability(String probability) {
		String oldProbability = this.probability;
		this.probability = probability;
		getListeners().firePropertyChange(PROPERTY_PROBABILITY, oldProbability, probability);
	}

	public String getProbability() {
		return probability;
	}
}