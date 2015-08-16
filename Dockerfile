from ruby:2.1

run \
    gem install bundler

# clone the capsulecd runner
run cd /srv/ && git clone https://github.com/AnalogJ/capsulecd.git

# copy the application files to the image
workdir /srv/capsulecd-webhook
copy . /srv/capsulecd-webhook/
run bundle install --path vendor/bundle



#finish up
expose 8080
cmd ["bundle", "exec", "thin", "start", "-p", "8080"]
