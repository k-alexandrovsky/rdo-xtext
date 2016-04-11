package ru.bmstu.rk9.rao.lib.simulator;

import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;

import ru.bmstu.rk9.rao.lib.exception.RaoLibException;
import ru.bmstu.rk9.rao.lib.resource.ComparableResource;
import ru.bmstu.rk9.rao.lib.resource.Resource;
import ru.bmstu.rk9.rao.lib.resource.ResourceManager;

public class ModelState {
	public ModelState(Collection<Class<?>> resourceClasses) {
		for (Class<?> resourceClass : resourceClasses) {
			if (!ComparableResource.class.isAssignableFrom(resourceClass))
				throw new RaoLibException(
						"Attempting to initialize model state with invalid resource type " + resourceClass);

			resourceManagers.put(resourceClass, new ResourceManager<>());
		}
	}

	private ModelState() {
	}

	@SuppressWarnings("unchecked")
	public <T extends ComparableResource<T>> void eraseResource(T resource) {
		ResourceManager<T> resourceManager = (ResourceManager<T>) resourceManagers.get(resource.getClass());
		if (resourceManager == null)
			throw new RaoLibException("Attempting to erase resource of non-existing type " + resource.getClass());

		resourceManager.eraseResource(resource);
	}

	@SuppressWarnings("unchecked")
	public <T extends ComparableResource<T>> void addResource(T resource) {
		ResourceManager<T> resourceManager = (ResourceManager<T>) resourceManagers.get(resource.getClass());
		if (resourceManager == null)
			throw new RaoLibException("Attempting to add resource of non-existing type " + resource.getClass());

		resourceManager.addResource(resource);
	}

	@SuppressWarnings("unchecked")
	public <T extends ComparableResource<T>> Collection<T> getAll(Class<T> cl) {
		return (Collection<T>) resourceManagers.get(cl).getAll();
	}

	@SuppressWarnings("unchecked")
	public <T extends ComparableResource<T>> Collection<T> getAccessible(Class<T> cl) {
		return (Collection<T>) resourceManagers.get(cl).getAccessible();
	}

	@SuppressWarnings({ "rawtypes", "unchecked" })
	public boolean checkEqual(ModelState other) {
		if (other == null)
			return false;

		if (other == this)
			return true;

		for (Class<?> resourceClass : resourceManagers.keySet()) {
			ResourceManager<?> resourceManager = resourceManagers.get(resourceClass);
			ResourceManager<?> resourceManagerOther = other.resourceManagers.get(resourceClass);

			if (!resourceManager.checkEqual((ResourceManager) resourceManagerOther))
				return false;
		}

		return true;
	}

	public final List<Resource> getAllResources() {
		List<Resource> resources = new ArrayList<>();
		for (ResourceManager<?> resourceManager : resourceManagers.values()) {
			resources.addAll(resourceManager.getAll());
		}
		return resources;
	}

	public void deploy() {
		Simulator.setModelState(this);
	}

	public ModelState deepCopy() {
		ModelState copy = new ModelState();
		for (Entry<Class<?>, ResourceManager<?>> entry : resourceManagers.entrySet()) {
			copy.resourceManagers.put(entry.getKey(), entry.getValue().deepCopy());
		}

		return copy;
	}

	private Map<Class<?>, ResourceManager<?>> resourceManagers = new HashMap<>();
}