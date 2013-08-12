class Plan < ActiveRecord::Base

	extend FriendlyId
	
	attr_accessible :locked, :project_id, :version_id, :version, :plan_sections

	#associations between tables
	belongs_to :project
	has_many :answers
	has_many :plan_sections
	belongs_to :version
	accepts_nested_attributes_for :project
	accepts_nested_attributes_for :answers
	accepts_nested_attributes_for :version
	
	friendly_id :project_and_phase, use: :slugged
  
	def answer(qid, create_if_missing = true)
  		answer = answers.where(:question_id => qid).order("created_at DESC").first
		if answer.nil? && create_if_missing then
			answer = Answer.new
			answer.plan_id = id
			answer.question_id = qid
		end
		return answer
	end
	
	def project_and_phase
		"#{project.title} #{version.phase.title}"
	end
	
	def sections
		sections = version.sections
		# add sections from organisation here
	end
	
	def guidance_for_question(question_id)
		# pulls together guidance from various sources for question
		question = Question.find(question_id)
		guidance = question.guidance
	end
	
	def can_edit(user_id)
		true
	end
	
	def can_read(user_id)
		true
	end
	
	def status
		status = {
			"num_questions" => 0,
			"num_answers" => 0,
			"sections" => {},
			"questions" => {}
		}
		sections.each do |s|
			section_questions = 0
			section_answers = 0
			status["sections"][s.id] = {}
			s.questions.each do |q|
				status["num_questions"] += 1
				section_questions += 1
				answer = answer(q.id, false)
				if ! answer.nil? then
					status["questions"][q.id] = {
						"answer_id" => answer.id,
						"answer_created_at" => answer.created_at.to_i,
						"answer_text" => answer.text,
						"answer_option_ids" => answer.option_ids
					}
					status["num_answers"] += 1
					section_answers += 1
				end
 				status["sections"][s.id]["num_questions"] = section_questions
 				status["sections"][s.id]["num_answers"] = section_answers
			end
		end
		return status
	end
	
	def locked(section_id, user_id)
		plan_section = plan_sections.where(:section_id => section_id).order("created_at DESC").first
		if plan_section.nil? then
			status = {
				"locked" => false,
				"current_user" => false,
				"timestamp" => nil,
				"id" => nil
			}
		else
			status = {
				"locked" => plan_section.release_time > Time.now,
				"current_user" => plan_section.user_id == user_id,
				"timestamp" => plan_section.updated_at,
				"id" => plan_section.id
			}
		end
	end
	
	def lock_all_sections(user_id)
		sections.each do |s|
			lock_section(s.id, user_id, 1800)
		end
	end
	
	def unlock_all_sections(user_id)
		plan_sections.where(:user_id => user_id).order("created_at DESC").each do |plan_section|
			unlock_plan_section(plan_section)
		end
	end
	
	def delete_recent_locks(user_id)
		plan_sections.where(:user_id => user_id, :created_at => 30.seconds.ago..Time.now).delete_all
	end
	
	def lock_section(section_id, user_id, release_time = 30)
		status = locked(section_id, user_id)
		if ! status["locked"] then
			plan_section = PlanSection.new
			plan_section.plan_id = id
			plan_section.section_id = section_id
			plan_section.release_time = Time.now + release_time.seconds
			plan_section.user_id = user_id
			plan_section.save
		elsif status["current_user"] then
			plan_section = PlanSection.find(status["id"])
			plan_section.release_time = Time.now + release_time.seconds
			plan_section.save
		else
			return false
		end
	end
	
	def unlock_section(section_id, user_id)
		plan_section = plan_sections.where(:section_id => section_id, :user_id => user_id).order("created_at DESC").first
		unlock_plan_section(plan_section, user_id)
	end
	
	def unlock_plan_section(plan_section, user_id)
		if plan_section.release_time > Time.now then
			plan_section.release_time = Time.now
			plan_section.save
		else
			return false
		end
	end
end
