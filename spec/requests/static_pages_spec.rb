require 'spec_helper'

describe "StaticPages" do
  describe "Home page" do
    it "should have the content 'Two-way Auth'" do
      visit '/'
      expect(page).to have_content('Twitterアカウントでサインイン')
    end
  end

  describe "Info page" do
    it "should have the content 'Info'" do
      visit '/info'
      expect(page).to have_content('Info')
    end
  end
end
