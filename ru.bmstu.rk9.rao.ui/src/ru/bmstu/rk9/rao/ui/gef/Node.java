package ru.bmstu.rk9.rao.ui.gef;

import java.beans.PropertyChangeListener;
import java.beans.PropertyChangeSupport;
import java.io.Serializable;
import java.util.ArrayList;
import java.util.List;

public class Node implements Serializable {

	private static final long serialVersionUID = 1;

	private List<Node> children;
	private Node parent;
	private PropertyChangeSupport listeners;
	public static final String PROPERTY_ADD = "NodeAddChild";
	public static final String PROPERTY_REMOVE = "NodeRemoveChild";

	public Node() {
		parent = null;
		children = new ArrayList<Node>();
		listeners = new PropertyChangeSupport(this);
	}

	public final boolean addChild(Node child) {
		boolean isAdded = this.children.add(child);
		if (isAdded) {
			child.setParent(this);
			getListeners().firePropertyChange(PROPERTY_ADD, null, child);
		}
		return isAdded;
	}

	public final boolean removeChild(Node child) {
		boolean isRemoved = this.children.remove(child);
		if (isRemoved)
			getListeners().firePropertyChange(PROPERTY_REMOVE, child, null);
		return isRemoved;
	}

	public final List<Node> getChildren() {
		return this.children;
	}

	public final Node getParent() {
		return this.parent;
	}

	public final void setParent(Node parent) {
		this.parent = parent;
	}

	public final PropertyChangeSupport getListeners() {
		return listeners;
	}

	public final void addPropertyChangeListener(PropertyChangeListener listener) {
		listeners.addPropertyChangeListener(listener);
	}

	public final void removePropertyChangeListener(PropertyChangeListener listener) {
		listeners.removePropertyChangeListener(listener);
	}

	public final boolean contains(Node child) {
		return children.contains(child);
	}
}