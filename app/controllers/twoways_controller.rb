require 'rexml/document'
require 'net/https'

class TwowaysController < ApplicationController
  before_action :signed_in_user, only: [:telephone, :telephone_confirm, :telephone_check, :sms, :sms_confirm, :sms_check]
  def telephone
  end

  def telephone_confirm
    if session[:secret].nil?
      phonenumber = params[:user][:phone]
      if phonenumber =~ /^0\d{10}$/
        secret = '%06d'%rand(0..999999)
        session[:secret] = secret
        call(phonenumber, secret)
      else
        flash.now[:error] = '最初からやり直してください'
        redirect_to root_url
      end
    else
      session[:secret] = nil
      flash.now[:error] = '最初からやり直してください'
      redirect_to root_url
    end
  end

  def telephone_check
    @success = session[:secret] == params[:user][:secret]
    session[:secret] = nil
  end

  def sms
  end

  def sms_confirm
    if session[:secret].nil?
      phonenumber = params[:user][:phone]
      if phonenumber =~ /^0\d{10}$/
        secret = '%06d'%rand(0..999999)
        session[:secret] = secret
        send_sms(phonenumber, secret)
      else
        flash.now[:error] = '最初からやり直してください'
        redirect_to root_url
      end
    else
      session[:secret] = nil
      flash.now[:error] = '最初からやり直してください'
      redirect_to root_url
    end
  end

  def sms_check
    @success = session[:secret] == params[:user][:secret]
    session[:secret] = nil
  end

  private
  # AsteriskのHTTPS経由のmxmlインターフェイスを使って、電話を使ってトークンを送信します
  # [phonenumber]
  #   通話先の番号を文字列表記したもの。
  # [token]
  #   送信するトークン
  # [return]
  #   通信に成功したらtrue
  def call(phone_number, token)
    config = Twostepauth::Application.config.asterisk
    query = URI.encode_www_form(:action => 'login', :username => config[:username], :secret => config[:password])
    uri = URI::HTTPS.build({:host => config[:host], :port => config[:port], :path => '/mxml', :query => query})
    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true
    https.ca_file = Rails.root.join('config/', config[:ca]).to_s
    https.verify_mode = OpenSSL::SSL::VERIFY_PEER
    https.start {|h|
      res = h.get(uri.request_uri)
      return false unless parse_response_is_success?(res.body)
      @cookie = res['Set-Cookie'].split(',').join(';')
      query = URI.encode_www_form(:action => 'Originate', :channel => "SIP/184#{phone_number}@fusion-smart", :context => 'default', :exten => "999#{token}", :priority => '1')
      res = h.get('/mxml?' + query, 'Cookie' => @cookie)
      return false unless parse_response_is_success?(res.body)
    }
    true
  end

  def send_sms(phone_number, token)
    config = Twostepauth::Application.config.asterisk
    client = Twilio::REST::Client.new(config[:twilio_sid], config[:twilio_authtoken])
    account = client.account
    message = account.sms.messages.create({:from => config[:twilio_phone], :to => phone_number.gsub(/^0/, '+81'), :body => "認証コードは #{token} です"})
    puts message
  end

  # [res]
  #   HTTPResponse
  def parse_session_id(res)
    cookie = {}
    res.get_fields('Set-Cookie').each{|str|
      k,v = str[0...str.index(';')].split('=')
      cookie[k] = v
    }
    'mainsession_id=' + cookie['mansession_id'][1..-2]
  end

  # Asteriskからのレスポンスの実行結果を真偽値に変換して返す
  # [body]
  #   XML形式のレスポンスボディ
  # [return]
  #   成功値ならtrue
  def parse_response_is_success?(body)
    doc = REXML::Document.new(body)
    REXML::XPath.first(doc, "//response/generic/attribute::response").to_s == 'Success'
  end
end
