require 'spec_helper'

RSpec.describe OmniAuth::Strategies::OAuth2MultipleState do
  let(:request) { double('Request', params: {}, cookies: {}, env: {}) }
  let(:app) { -> { [200, {}, ['Hello.']] } }

  subject do
    OmniAuth::Strategies::OAuth2MultipleState.new(app, 'client_id', 'client_secret', {
                                                    client_options: {
                                                      site: 'https://example.com',
                                                      authorize_url: '/oauth/authorize',
                                                      token_url: '/oauth/token'
                                                    }
                                                  }).tap do |strategy|
      allow(strategy).to receive(:request) { request }
    end
  end

  describe '#client' do
    it 'has the correct client options' do
      expect(subject.client.site).to eq('https://example.com')
      expect(subject.client.options[:authorize_url]).to eq('/oauth/authorize')
      expect(subject.client.options[:token_url]).to eq('/oauth/token')
    end
  end

  describe '#authorize_params' do
    before do
      states = (1..5).map { |i| "state#{i}" }
      origins = (1..5).map { |i| ["state#{i}", 'origin'] }.to_h

      allow(subject).to receive(:session).and_return({
                                                       'omniauth.origin' => 'origin',
                                                       'omniauth.states' => states,
                                                       'omniauth.state_origins' => origins
                                                     })

      allow(subject).to receive(:env).and_return({})
      subject.options.authorize_params = {}
    end

    it 'includes the state parameter' do
      allow(SecureRandom).to receive(:hex).and_return('state123')
      expect(subject.authorize_params[:state]).to eq('state123')
    end

    it 'trims omniauth.states to the last 5 entries' do
      allow(SecureRandom).to receive(:hex).and_return('state6')
      subject.authorize_params

      expect(subject.session['omniauth.states'].length).to eq(5)
      expect(subject.session['omniauth.states']).to eq(%w[state2 state3 state4 state5 state6])
    end

    it 'trims omniauth.state_origins to the last 5 entries' do
      allow(SecureRandom).to receive(:hex).and_return('state6')
      subject.authorize_params

      expect(subject.session['omniauth.state_origins'].length).to eq(5)
      expect(subject.session['omniauth.state_origins']).to eq({
                                                                'state2' => 'origin',
                                                                'state3' => 'origin',
                                                                'state4' => 'origin',
                                                                'state5' => 'origin',
                                                                'state6' => 'origin'
                                                              })
    end
  end

  describe '#request_phase' do
    before do
      allow(subject).to receive(:session).and_return({
                                                       'omniauth.origin' => '',
                                                       'omniauth.states' => [],
                                                       'omniauth.state_origins' => {}
                                                     })
    end

    it 'redirects to the authorize URL' do
      allow(SecureRandom).to receive(:hex).and_return('state6')
      allow(subject).to receive(:callback_url).and_return('https://example.com/callback')
      encoded_url = CGI.escape('https://example.com/callback')
      expect(subject).to receive(:redirect).with("https://example.com/oauth/authorize?client_id=client_id&redirect_uri=#{encoded_url}&response_type=code&state=state6")
      subject.request_phase
    end
  end

  describe '#callback_phase' do
    let(:request) { instance_double('ActionDispatch::Request', params: { 'state' => 'state123', 'code' => 'auth_code' }) }
    let(:env) { {} }

    before do
      allow(subject).to receive(:request).and_return(request)
      allow(subject).to receive(:session).and_return({
        'omniauth.states' => ['state123'],
        'omniauth.state_origins' => { 'state123' => 'origin' }
      })
      allow(subject).to receive(:env).and_return(env)
    end

    context 'when state does not match' do
      it 'raises a CallbackError' do
        allow(subject).to receive(:session).and_return({
        'omniauth.states' => ['invalid_state'],
        'omniauth.state_origins' => { 'invalid_state' => 'origin' }
        })

        allow(subject).to receive(:fail!) do |_, exception|
          raise exception
        end

        expect { subject.callback_phase }.to raise_error(OmniAuth::Strategies::OAuth2MultipleState::CallbackError) do |error|
          expect(error.error).to eq(:csrf_detected)
          expect(error.error_reason).to eq('CSRF detected')
          expect(error.error_uri).to be_nil
          expect(error.message).to eq('csrf_detected | CSRF detected')
        end
      end
    end
  end
end
