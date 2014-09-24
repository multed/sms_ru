#!/usr/bin/env ruby 

require 'net/http'
require 'json'
require 'docopt'

class SMS
	def initialize
		@statuses = {
			'-1' => 'Сообщение не найдено.',
			'100' => 'Сообщение находится в нашей очереди',
			'101' => 'Сообщение передается оператору',
			'102' => 'Сообщение отправлено (в пути)',
			'103' => 'Сообщение доставлено',
			'104' => 'Не может быть доставлено: время жизни истекло',
			'105' => 'Не может быть доставлено: удалено оператором',
			'106' => 'Не может быть доставлено: сбой в телефоне',
			'107' => 'Не может быть доставлено: неизвестная причина',
			'108' => 'Не может быть доставлено: отклонено',
			'200' => 'Неправильный api_id',
			'210' => 'Используется GET, где необходимо использовать POST',
			'211' => 'Метод не найден',
			'220' => 'Сервис временно недоступен, попробуйте чуть позже.',
			'300' => 'Неправильный token (возможно истек срок действия, либо ваш IP изменился)',
			'301' => 'Неправильный пароль, либо пользователь не найден',
			'302' => 'Пользователь авторизован, но аккаунт не подтвержден (пользователь не ввел код, присланный в регистрационной смс)',
		}
	end

	def Send(data)
        uri = URI('http://sms.ru/sms/send')
        params = { :api_id => data["--api-id"] }
        params[:partner_id] = 40129 unless data["--no-partner"]
        params[:to] = data["--to"]
        params[:from] = data["--from"] if data["--from"]
        params[:text] = data["--message"]
        params[:test] = data["--test"] if data["--test"]

		puts "Отправляем смс на номер: " + params[:to]

        uri.query = URI.encode_www_form(params)
        response = Net::HTTP.get_response(uri)
        case response
        when Net::HTTPSuccess then
            r = response.body.split("\n")
            puts "Статус ответа: " + Statuses(r[0])
            puts "Идентификатор сообщения для проверки статуса: " + r[1]
            puts r[2]
        else
            puts response.value
        end
	end

	def Ballance(apikey)
		puts "Проверяем баланс."
		uri = URI('http://sms.ru/my/balance')
        params = {
            :api_id => apikey,
        }
        uri.query = URI.encode_www_form(params)
        response = Net::HTTP.get_response(uri)
        print "Баланс: ", response.body.split("\n")[1], "\n" if response.is_a?(Net::HTTPSuccess)
	end

	def Status(apikey,smsid)
		uri = URI('http://sms.ru/sms/status')
        params = {
            :api_id => apikey,
            :id => smsid,
        }
        uri.query = URI.encode_www_form(params)
        response = Net::HTTP.get_response(uri)
        r = response.body.split("\n")[0]
        print "Статус: ", Statuses(r), "\n" if response.is_a?(Net::HTTPSuccess)
	end
	
	private

	def Statuses(s)
		if s.empty?
			'None'
		else
			@statuses["#{s}"]
		end
	end
end

doc =<<EOF
Usage:
 #{__FILE__} send --api-id=<ID> --to=<НОМЕР> --message=<TEXT> [--no-partner]
 #{__FILE__} balance --api-id=<ID>
 #{__FILE__} status --api-id=<ID> --sms-id=<SMSID>

Commands:
  send                Отправить смс
  balance            Проверить баланс
  status              Проверить статус отправленной смс
Option:
  -h --help           Показать это сообщение
  --api-id=<ID>       API ID сервиса sms.ru, который можно получить на http://multed.sms.ru
  --message="<TEXT>"  Текст sms-сообщения.
  --to=<NUMBER>       Номер, на который шлем sms.
  --from=<NAME>       Отправитель смс. Должен быть согласован с администрацией сервиса.
  --sms-id=<SMSID>    Идентификатор смс
  --no-partner        Не учитывать мой код партнера. С кодом разработчик получает комиссию от посланных вами смс.
EOF

begin
  arguments = Docopt::docopt(doc)
rescue Docopt::Exit => e
  puts e.message
  exit
end

a = SMS.new

if arguments["send"]
	if arguments["--api-id"] and arguments["--message"] and arguments["--to"]
		a.Send arguments
	else 
		puts "Не хватает обязательных параметров."
	end
elsif arguments["balance"]
	if arguments["--api-id"]
		a.Ballance arguments["--api-id"]
	else 
		puts "Необходимо ввести API ID."
	end
elsif arguments["status"]
	if arguments["--sms-id"]
		a.Status arguments["--api-id"], arguments["--sms-id"]
	else
		puts "Не указали --sms-id"
	end
end


