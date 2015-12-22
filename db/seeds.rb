# This file should contain all the record creation needed to seed the database with its default
#   values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
require 'active_support/all'

job = JobService.instance
invitation = InvitationService.instance
offer = OfferService.instance
created = job.create(name: 'Security man for party', description: 'A security man is needed for '\
                     'multiple parties around the city.', owner_id: 23, due_date: Date.today + 20,
                     invitation_only: false, start_date: Date.today.next_month,
                     finish_date: Date.today.next_month.next_day,
                     metadata: { payment: 100, hours_per_day: 5, experience: '5 months or more',
                                 min_height: '6 feet' } )
job.activate(created.id)
inv = invitation.create_new(provider_id: 5, job_id: created.id,
                            description: "Hello, I'm wondering if you have any security man "\
                                         "available for this job.")
invitation.send(inv.id)

created = job.create(name: 'DJ for electronic music.', description: 'A DJ for multiple music '\
                     'festivals is required.', owner_id: 23, due_date: Date.today + 15,
                     invitation_only: true, start_date: Date.today.next_month,
                     finish_date: Date.today.next_month.next_day,
                     metadata: { payment: 250, hours_per_day: 3, experience: '1 year or more',
                                 min_songs: 15 } )
job.activate(created.id)
inv = invitation.create_new(provider_id: 8, job_id: created.id,
                            description: "Hey, I'd like you to play in my party, would you?")
invitation.send(inv.id)
invitation.accept(inv.id)
offr = offer.create(job_id: created.id, invitation_id: inv.id, provider_id: 8,
                    description: "Okay, I will play in those festivals, but look at the payment "\
                                 "I require.",
                    metadata: { payment: 270, hours_per_day: 3, experience: '1 year or more',
                                min_songs: 15 } )
offer.send(offr.id)
offer.accept(offr.id)

created = job.create(name: 'Italian chef for a dinner.', description: 'I need an experimented '\
                     'chef for cooking in an important dinner.', owner_id: 15,
                     due_date: Date.today + 25, invitation_only: false,
                     start_date: Date.today.next_month, finish_date: Date.today.next_month.next_day,
                     metadata: { payment: 260, work_hours: 5, experience: '2 years or more',
                                 recipes: ["pizza", "lasagna", "lobardia"] } )
job.activate(created.id)
inv = invitation.create_new(provider_id: 3, job_id: created.id,
                            description: "You are a good chef, would you like to cook in my party?")

job.create(name: 'Deliver a medium package', description: 'I need a delivery man to carry a 25 '\
           'pounds box to Miami', owner_id: 90, due_date: Date.today + 10, invitation_only: false,
           metadata: { payment: 110, origin_address: '342 North 2nd Street, Phoenix, AZ 85005',
                       destination_address: '18th Ave, Suite 301, Miami, Fl. 33179' },
           start_date: Date.today.next_month, finish_date: Date.today.next_month.next_day, )
