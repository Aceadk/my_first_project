const { expect } = require('chai');

process.env.FIREBASE_CONFIG = process.env.FIREBASE_CONFIG || JSON.stringify({
  projectId: 'demo-project',
  databaseURL: 'https://demo-project.firebaseio.com',
});

const functions = require('../lib/index.js');

describe('input sanitization policy (SEC-BE-003)', () => {
  const { stripHtml, validateMessageContent, validateProfileName, validateBio } =
    functions.__test__helpers;

  describe('stripHtml', () => {
    it('removes complete script/markup tags', () => {
      expect(stripHtml('<script>alert(1)</script>hello')).to.equal('alert(1)hello');
      expect(stripHtml('<b>bold</b>')).to.equal('bold');
    });

    it('removes a trailing unterminated tag start (no closing ">")', () => {
      // The naive /<[^>]*>/g stripper leaves this intact; the hardened version
      // must drop it because a browser would still parse it once markup follows.
      expect(stripHtml('hi <img src=x onerror=alert(1)')).to.equal('hi ');
      expect(stripHtml('caption </a')).to.equal('caption ');
    });

    it('neutralizes the "><script> attribute-breakout payload', () => {
      const cleaned = stripHtml('"><script>alert(document.cookie)</script>');
      expect(cleaned).to.not.contain('<');
      expect(cleaned).to.not.contain('</script');
    });

    it('preserves benign "<" usage that is not a tag start', () => {
      expect(stripHtml('3 < 5')).to.equal('3 < 5');
      expect(stripHtml('i <3 you')).to.equal('i <3 you');
    });
  });

  describe('validators apply sanitization', () => {
    it('strips markup from message content', () => {
      expect(validateMessageContent('<b>hey</b> there')).to.equal('hey there');
    });

    it('strips markup from profile name and enforces the min length', () => {
      expect(validateProfileName('<i>Ava</i>')).to.equal('Ava');
      expect(() => validateProfileName('<b>a</b>')).to.throw();
    });

    it('strips markup from bio and allows empty', () => {
      expect(validateBio('<span>hi</span>')).to.equal('hi');
      expect(validateBio('')).to.equal('');
      expect(validateBio(null)).to.equal('');
    });
  });
});
