/* global cy */
/// <reference types="cypress" />

context('Documentation', () => {
  beforeEach(() => {
    cy.visit('')
  })
  describe('landing article', () => {
    it('should have content prose', () => {
      cy.title('documentation')
      cy.get('h1')
        .contains('Documentation')
        .parents('article')
        .find('section > h2')
        .contains('Alphabetical index')
        .parents('article')
        .contains('Subject index')
    })

    describe('generated indexes', () => {
      it('should contain articles by alphabet', () => {
        cy.get('[name=alphabetical-index]')
          .parents('section')
          .contains('Integration Testing')
      })

      it('should contain articles by subject', () => {
        cy.get('[name=subject-index]')
          .parents('section')
          .contains('Integration Testing')
      })
    })

    it('should have ToC links', () => {
      cy.get('#sidebar')
        .find('.toc')
        .within(($toc) => {
          cy.get('li')
            .contains('Getting Started')
            .click()
            .url()
            .should('include', '#start')
        })
    })

    describe('navbar', () => {
      it('should enable simple search', () => {
        cy.get('.form-control')
          .type('testing{enter}')
          .url().should('include', 'search.html')
        cy.get('body')
          .find('#f-results')
          .contains('Integration Testing')
          .click()
          .url()
          .should('include', 'integration-testing.xml')
      })

      it('should reference author guidelines', () => {
        cy.get('.navbar')
          .find('#development')
          .click()
          .find('[href="author-reference.xml"]')
          .click()
          .url()
          .should('include', 'author-reference.xml')
      })
    })
  })
})
