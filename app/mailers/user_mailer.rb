class UserMailer < ActionMailer::Base
	default from: 'e-ciencia@madrimasd.org'
	
	def sharing_notification(project_group)
		@project_group = project_group
		mail(to: @project_group.user.email, subject: "Te han concedido permisos para acceder a un Plan de Gestión de Datos")
	end
	
	def permissions_change_notification(project_group)
		@project_group = project_group
		mail(to: @project_group.user.email, subject: "Cambios en los privilegios de acceso al PGD")
	end
	
	def project_access_removed_notification(user, project)
		@user = user
		@project = project
		mail(to: @user.email, subject: "Eliminados los privilegios de acceso al PGD")
	end
end
