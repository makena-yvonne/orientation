require "spec_helper"

describe Article do
  context "after_save" do
    let(:article) { create(:article) }
    let(:user) { create(:user) }
    let!(:article_subscription) { 
      create(:article_subscription, article: article, user: user)
    }

    let(:subject) { article.save!}

    it "notifies ArticleSubscription about the change" do
      ArticleSubscription.any_instance.should_receive(:send_update_for).with(article.reload.id)
      subject
    end
  end

  context '#author?(user)' do
    let!(:article) { create(:article) }
    let(:user) { nil }

    subject(:author?) { article.author?(user) }

    context 'when the user is the article author' do
      let(:user) { article.author }

      it "returns true" do
        expect(author?).to be_truthy
      end
    end

    context 'when the user is not the article author' do
      let(:user) { create(:user) }

      it "return false" do
        expect(author?).to be_falsey
      end
    end
  end

  context ".fresh" do
    let!(:fresh_article) { create(:article, :fresh) }
    let!(:stale_article) { create(:article, :stale) }

    let(:subject) { Article.fresh }

    it "includes fresh articles" do
      subject.should include(fresh_article)
    end

    it "does not include stale articles" do
      subject.should_not include(stale_article)
    end
  end

  context ".fresh?" do
    let(:fresh_article) { create(:article) }
    let(:stale_article) { create(:article, :stale) }

    it "is true for fresh articles" do
      Article.fresh?(fresh_article).should be_truthy
    end

    it "is false for stale articles" do
      Article.fresh?(stale_article).should be_falsey
    end
  end

  context ".stale" do
    let!(:fresh_article) { create(:article, :fresh) }
    let!(:stale_article) { create(:article, :stale) }

    let(:subject) { Article.stale }

    it "includes stale articles" do
      subject.should include(stale_article)
    end

    it "does not include fresh articles" do
      subject.should_not include(fresh_article)
    end
  end

  context ".stale?" do
    let(:fresh_article) { create(:article) }
    let(:stale_article) { create(:article, :stale) }

    it "is true for stale articles" do
      Article.stale?(stale_article).should be_truthy
    end

    it "is false for fresh articles" do
      Article.stale?(fresh_article).should be_falsey
    end
  end

  context ".text_search" do
    let!(:article) { create :article, title: "Pumpernickel Stew", content: "Yum!"}

    it "does partial title matching" do
      result = Article.text_search "Stew"
      expect(result).to include(article)
    end

    it "does full title matching" do
      result = Article.text_search article.title
      expect(result).to include(article)
    end

    it "does partial content matching" do
      result = Article.text_search "yum"
      expect(result).to include(article)
    end

    it "does full content matching" do
      result = Article.text_search article.content
      expect(result).to include(article)
    end
  end

  context ".ordered_current" do
    let!(:recent_article) { create :article }
    let!(:more_recent_article) { create :article }
    let!(:archived_article) { create :article, :archived }

    it "returns the more recent article first" do
      expect(Article.ordered_current.first).to eq more_recent_article
    end
	
    it "does not include archived articles" do
      expect(Article.ordered_current).to_not include(archived_article)
    end
  end

  context ".ordered_fresh" do
    let!(:recent_article) { create :article }
    let!(:more_recent_article) { create :article }
    let!(:archived_article) { create :article, :archived }
    let!(:rotten_article) { create :article, :rotten }

    it "returns the more recent article first" do
      expect(Article.ordered_fresh.first).to eq more_recent_article
    end

    it "does not include archived articles" do
      expect(Article.ordered_fresh).to_not include(archived_article)
    end

    it "does not include rotten articles" do
      expect(Article.ordered_fresh).to_not include(archived_article)
    end

    context "with an updated article" do
      before { recent_article.touch }

      it "returns the updated article first" do
        expect(Article.ordered_fresh.first).to eq recent_article
      end
    end
  end

  context "#archive!" do
    let!(:article) { create :article }

    subject(:archive_article) { article.archive! }

    it "removes the article from current articles" do
      expect { archive_article }.to change { Article.current.count }.by(-1)
    end
  end

  context "#fresh?" do
    subject(:fresh?) { article.fresh? }

    context 'with a fresh article' do
      let(:article) { create(:article, :fresh) }

      it "returns true" do
        expect(fresh?).to be_truthy
      end
    end

    context 'with a stale article' do
      let(:article) { create(:article, :stale) }

      it "returns false" do
        expect(fresh?).to be_falsey
      end
    end

    context 'with a rotten article' do
      let(:article) { create(:article, :rotten) }

      it "returns false" do
        expect(fresh?).to be_falsey
      end
    end
  end

  context "#refresh!" do
    subject(:refresh!) { article.refresh! }

    context 'with a fresh article' do
      let(:article) { create(:article, :fresh) }

      it "keeps it fresh" do
        expect { refresh! }.not_to change { article.fresh? }
      end
    end

    context 'with a stale article' do
      let(:article) { create(:article, :stale) }

      it "makes it fresh" do
        expect { refresh! }.to change { article.fresh? }
      end
    end

    context 'with a rotten article' do
      let(:article) { create(:article, :rotten) }

      it "makes it fresh" do
        expect { refresh! }.to change { article.fresh? }
      end
    end
  end

  context "#rot!" do
    subject(:rot!) { article.rot! }

    context 'with a fresh article' do
      let(:article) { create(:article, :fresh) }

      it "makes it rotten" do
        expect { rot! }.to change { article.rotten? }
      end
    end

    context 'with a stale article' do
      let(:article) { create(:article, :stale) }

      it "makes it rotten" do
        expect { rot! }.to change { article.rotten? }
      end
    end

    context 'with a rotten article' do
      let(:article) { create(:article, :rotten) }

      it "keeps it rotten" do
        expect { rot! }.not_to change { article.rotten? }
      end
    end
  end

  context "#rotten?" do
    let(:fresh_article) { create(:article, :fresh) }
    let(:stale_article) { create(:article, :stale) }
    let(:rotten_article) { create(:article, :rotten) }

    it "returns false for a fresh article" do
      fresh_article.rotten?.should be_falsey
    end

    it "returns false for a stale article" do
      fresh_article.rotten?.should be_falsey
    end

    it "returns true for a rotten article" do
      rotten_article.rotten?.should be_truthy
    end
  end

  context "#stale?" do
    let(:fresh_article) { create(:article, :fresh) }
    let(:stale_article) { create(:article, :stale) }

    it "returns false for a non-stale article" do
      fresh_article.stale?.should be_falsey
    end

    it "returns true for a stale article" do
      stale_article.stale?.should be_truthy
    end
  end

  context "#unarchive!" do
    let!(:article) { create :article }

    subject(:unarchive_article) { article.unarchive! }

    before { article.archive! }

    it "add the article to current articles" do
      expect { unarchive_article }.to change { Article.current.count }.by(1)
    end
  end
end
