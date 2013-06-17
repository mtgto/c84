require 'spec_helper'

describe "StaticPages" do
  describe "Home page" do
    it "should have the content 'Two-way Auth'" do
      visit '/static_pages/home'
      expect(page).to have_content('Two-way Auth')
    end
  end

  describe "Info page" do
    it "should have the content 'Info'" do
      visit '/static_pages/info'
      expect(page).to have_content('Info')
    end
  end
end
