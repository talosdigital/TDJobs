FROM rails:onbuild
ENV RAILS_ENV production
ENV TDJOBS_DATABASE_USER postgres
ENV TDJOBS_DATABASE_PASSWORD postgres
ENV TDJOBS_DATABASE_HOST tdjobs_db
CMD ["bundle", "exec", "puma"]
