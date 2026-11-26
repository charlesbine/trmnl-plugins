# frozen_string_literal: true

require 'json'

RSpec.describe 'LLM Benchmark Leaders' do
  let(:mocks) do
    { 'https://api.zeroeval.com/leaderboard/models/full?justCanonicals=true' => {
      json: JSON.parse(File.read(File.join(__dir__, 'fixtures/models.json')))
    } }
  end
  let(:now) { Time.utc(2026, 11, 6, 12) }
  it_behaves_like 'a publishable recipe'

  it 'uses the X screen height for ranked rows and preserves the model names' do
    screen = trmnl.render(view: 'full', device: 'v2', orientation: :landscape, mocks:, now:)
    metrics = screen.evaluate(<<~JS)
      (() => {
        const table = document.querySelector('.benchmark-table');
        const rows = [...table.tBodies[0].rows].filter(row => row.offsetHeight > 0);
        const bounds = table.getBoundingClientRect();
        const layout = table.parentElement.getBoundingClientRect();
        return {
          names: rows.map(row => row.cells[0].textContent.trim()),
          fill: bounds.height / layout.height,
          topGap: Math.abs(bounds.top - layout.top),
          bottom: bounds.bottom,
          footer: document.querySelector('.title_bar').getBoundingClientRect().top
        };
      })()
    JS
    expect(metrics.fetch('names').length).to be > 8
    expect(metrics.fetch('names')).to include('Claude Mythos Preview')
    expect(metrics.fetch('fill')).to be_between(0.90, 1.01)
    expect(metrics.fetch('topGap')).to be < 2
    expect(metrics.fetch('bottom')).to be <= metrics.fetch('footer') + 1
  end

  %w[full half_horizontal half_vertical quadrant].each do |view|
    %i[landscape portrait].each do |orientation|
      it "fits #{view} in #{orientation}" do
        screen = trmnl.render(view:, orientation:, device: 'og_png', mocks:, now:)
        expect(screen).to have_no_problems.and(have_no_leaked_text).and(have_no_overflow)
          .and(have_no_overlapping_text).and(fit_image_size_limit)
        expect(screen).to have_css('.layout').and(have_css('.title_bar'))
      end
    end
  end
end
