package ru.bmstu.rk9.rao.jvmmodel

import com.google.inject.Inject
import org.eclipse.xtext.xbase.jvmmodel.AbstractModelInferrer
import org.eclipse.xtext.xbase.jvmmodel.IJvmDeclaredTypeAcceptor
import org.eclipse.xtext.xbase.jvmmodel.JvmTypesBuilder
import ru.bmstu.rk9.rao.rao.RaoModel
import org.eclipse.xtext.naming.QualifiedName
import ru.bmstu.rk9.rao.rao.Constant
import ru.bmstu.rk9.rao.rao.FunctionDeclaration
import org.eclipse.xtext.common.types.JvmVisibility

import static extension ru.bmstu.rk9.rao.jvmmodel.RaoNaming.*

import ru.bmstu.rk9.rao.rao.Event
import ru.bmstu.rk9.rao.rao.DefaultMethod
import ru.bmstu.rk9.rao.lib.simulator.TerminateCondition
import org.eclipse.xtext.common.types.JvmDeclaredType
import ru.bmstu.rk9.rao.rao.ResourceType
import org.eclipse.xtext.common.types.JvmPrimitiveType
import java.nio.ByteBuffer
import ru.bmstu.rk9.rao.rao.ResourceDeclaration

// TODO add override annotation to all generated overriden methods
class RaoJvmModelInferrer extends AbstractModelInferrer {
	@Inject extension JvmTypesBuilder

	def dispatch void infer(RaoModel element, IJvmDeclaredTypeAcceptor acceptor, boolean isPreIndexingPhase) {
		acceptor.accept(element.toClass(QualifiedName.create(element.eResource.URI.projectName, element.nameGeneric))) [
			final = true
			for (entity : element.objects) {
				entity.compileRaoEntity(it, isPreIndexingPhase)
			}
		]
	}

	def dispatch compileRaoEntity(Constant constant, JvmDeclaredType it, boolean isPreIndexingPhase) {
		members += constant.toField(constant.constant.name, constant.constant.parameterType) [
			visibility = JvmVisibility.PUBLIC
			static = true
			final = true
			initializer = constant.value
		]
	}

	def dispatch compileRaoEntity(FunctionDeclaration function, JvmDeclaredType it, boolean isPreIndexingPhase) {
		members += function.toMethod(function.name, function.type) [
			for (param : function.parameters)
				parameters += function.toParameter(param.name, param.parameterType)
			visibility = JvmVisibility.PUBLIC
			static = true
			final = true
			body = function.body
		]
	}

	def dispatch compileRaoEntity(DefaultMethod method, JvmDeclaredType it, boolean isPreIndexingPhase) {
		switch (method.name) {
			case "init": {
				members += method.toMethod(method.name, typeRef(void)) [
					visibility = JvmVisibility.PROTECTED
					static = true
					final = true
					body = method.body
				]
			}
			case "terminateCondition": {
				members += method.toClass("terminateCondition") [
					superTypes += typeRef(TerminateCondition)
					visibility = JvmVisibility.PROTECTED
					static = true
					final = true
					members += method.toMethod("check", typeRef(boolean)) [
						visibility = JvmVisibility.PUBLIC
						final = true
						body = method.body
					]
				]
			}
		}
	}

	def dispatch compileRaoEntity(ResourceType resourceType, JvmDeclaredType it, boolean isPreIndexingPhase) {
		members += resourceType.toClass(QualifiedName.create(qualifiedName, resourceType.name)) [
			static = true
			final = true

			superTypes += typeRef(ru.bmstu.rk9.rao.lib.resource.Resource)
			superTypes += typeRef(ru.bmstu.rk9.rao.lib.resource.ResourceComparison, { typeRef })

			members += resourceType.toMethod("create", typeRef) [
				visibility = JvmVisibility.PUBLIC
				static = true
				for (param : resourceType.parameters)
					parameters += param.toParameter(param.declaration.name, param.declaration.parameterType)
				body = '''
					return new «resourceType.name»(«FOR param : parameters»«
						param.name»«
						IF parameters.indexOf(param) != parameters.size - 1», «ENDIF»«ENDFOR»);
				'''
			]

			members += resourceType.toConstructor [
				visibility = JvmVisibility.PRIVATE
				for (param : resourceType.parameters)
					parameters += param.toParameter(param.declaration.name, param.declaration.parameterType)
				body = '''
					«FOR param : parameters»
						this._«param.name» = «param.name»;
					«ENDFOR»
				'''
			]

			for (param : resourceType.parameters) {
				members += param.toField("_" + param.declaration.name, param.declaration.parameterType) [ 
					initializer = param.^default
				]
				members += param.toMethod("get" + param.declaration.name.toFirstUpper, param.declaration.parameterType) [
					body = '''
						return _«param.declaration.name»;
					'''
				]
				members += param.toMethod("set" + param.declaration.name.toFirstUpper, typeRef(void)) [
					parameters += param.toParameter(param.declaration.name, param.declaration.parameterType) 
					body = '''
						this._«param.declaration.name» = «param.declaration.name»;
					'''
				]
			}

			members += resourceType.toMethod("checkEqual", typeRef(boolean)) [ m |
				m.visibility = JvmVisibility.PUBLIC
				m.parameters += resourceType.toParameter("other", typeRef)
				m.body = '''
					return «String.join(" && ", resourceType.parameters.map[ p |
						'''«IF p.declaration.parameterType.type instanceof JvmPrimitiveType
								»this._«p.declaration.name» == other._«p.declaration.name»«
							ELSE
								»this._«p.declaration.name».equals(other._«p.declaration.name»)«
							ENDIF»
						'''
					])»;
				'''
			]

			members += resourceType.toMethod("serialize", typeRef(ByteBuffer)) [
				visibility = JvmVisibility.PUBLIC
				body = '''
					return null;
				'''
			]

			members += resourceType.toMethod("getName", typeRef(String)) [
				visibility = JvmVisibility.PUBLIC
				body = '''
					return null;
				'''
			]

			members += resourceType.toMethod("getNumber", typeRef(Integer)) [
				visibility = JvmVisibility.PUBLIC
				body = '''
					return -1;
				'''
			]

			members += resourceType.toMethod("getTypeName", typeRef(String)) [
				visibility = JvmVisibility.PUBLIC
				final = true
				body = '''
					return "«resourceType.fullyQualifiedName»";
				'''
			]
		]
	}

	def dispatch compileRaoEntity(ResourceDeclaration resource, JvmDeclaredType it, boolean isPreIndexingPhase) {
		if (!isPreIndexingPhase && resource.constructor != null)
			members += resource.toField(resource.name, resource.constructor.inferredType) [
				visibility = JvmVisibility.PUBLIC
				static = true
				final = true
				initializer = resource.constructor
			]
	}

	def dispatch compileRaoEntity(Event event, JvmDeclaredType it, boolean isPreIndexingPhase) {
		members += event.toClass(QualifiedName.create(qualifiedName, event.name)) [
			static = true
			final = true
			
			superTypes += typeRef(ru.bmstu.rk9.rao.lib.event.Event)

			members += event.toConstructor [
				visibility = JvmVisibility.PUBLIC
				parameters += event.toParameter("time", typeRef(double))
				for (param : event.parameters)
					parameters += param.toParameter(param.name, param.parameterType)
				body = '''
					«FOR param : parameters»this.«param.name» = «param.name»;
					«ENDFOR»
				'''
			]

			for (param : event.parameters)
				members += param.toField(param.name, param.parameterType)

			members += event.toMethod("getName", typeRef(String)) [
				visibility = JvmVisibility.PUBLIC
				final = true
				body = '''
					return "«event.name»";
				'''
			]

			members += event.toMethod("run", typeRef(void)) [
				visibility = JvmVisibility.PUBLIC
				final = true
				body = event.body
			]

			members += event.toMethod("plan", typeRef(void)) [
				visibility = JvmVisibility.PUBLIC
				static = true
				final = true

				parameters += event.toParameter("time", typeRef(double))
				for (param : event.parameters)
					parameters += event.toParameter(param.name, param.parameterType)

				body = '''
					«event.name» event = new «event.name»(«FOR param : parameters»«
							param.name»«
							IF parameters.indexOf(param) != parameters.size - 1», «ENDIF»«ENDFOR»);
					pushEvent(event);
				'''
			]
		]
	}
}
